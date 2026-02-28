import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import 'package:fluttermint/src/cli/prompts/prompt_utils.dart';
import 'package:fluttermint/src/config/forge_config.dart';
import 'package:fluttermint/src/config/platform_config.dart';

class PlatformCommand extends Command<void> {
  @override
  final String name = 'platform';

  @override
  final String description =
      'Manage platforms in an existing FlutterMint project.\n'
      'Usage: fluttermint platform              — show enabled platforms\n'
      '       fluttermint platform add          — interactively add platforms\n'
      '       fluttermint platform add web macos — add specific platforms\n'
      '       fluttermint platform remove       — interactively remove platforms';

  @override
  Future<void> run() async {
    final projectPath = Directory.current.path;

    final forgeConfig = ForgeConfig.load(projectPath);
    if (forgeConfig == null) {
      stderr.writeln(
        'Error: No FlutterMint project found in the current directory.',
      );
      stderr.writeln(
        'Make sure you are inside a project created with "fluttermint create".',
      );
      return;
    }

    final rest = argResults?.rest ?? [];

    if (rest.isEmpty) {
      _showPlatforms(forgeConfig);
      return;
    }

    final action = rest.first;
    final requestedIds = rest.skip(1).toList();

    if (action == 'add') {
      await _addPlatforms(projectPath, forgeConfig, requestedIds);
    } else if (action == 'remove') {
      await _removePlatforms(projectPath, forgeConfig);
    } else {
      stderr.writeln('Unknown subcommand "$action". Use: platform add | platform remove');
    }
  }

  void _showPlatforms(ForgeConfig config) {
    print('');
    print('Enabled platforms:');
    for (final id in config.platforms) {
      final info = PlatformRegistry.byId(id);
      final label = info?.displayName ?? id;
      final tag =
          PlatformRegistry.defaultPlatformIds.contains(id)
              ? ' (default)'
              : '';
      print('  + $label$tag');
    }

    final available =
        PlatformRegistry.allPlatforms
            .where((p) => !config.platforms.contains(p.id))
            .toList();
    if (available.isNotEmpty) {
      print('');
      print('Available platforms:');
      for (final p in available) {
        print('  - ${p.id}: ${p.displayName}');
      }
      print('');
      print('Add with: fluttermint platform add <platform>');
    }
    print('');
  }

  Future<void> _addPlatforms(
    String projectPath,
    ForgeConfig forgeConfig,
    List<String> requestedIds,
  ) async {
    List<String> platformsToAdd;

    if (requestedIds.isEmpty) {
      // Interactive mode
      final available =
          PlatformRegistry.allPlatforms
              .where((p) => !forgeConfig.platforms.contains(p.id))
              .toList();

      if (available.isEmpty) {
        print('All platforms are already enabled!');
        return;
      }

      print('');
      print('  Available platforms:');
      for (var i = 0; i < available.length; i++) {
        print('    ${i + 1}) ${available[i].displayName} (${available[i].id})');
      }
      print('');

      final input = PromptUtils.askText(
        '  Enter platform numbers to add (comma-separated)',
      );
      final indices =
          input
              .split(',')
              .map((s) => int.tryParse(s.trim()))
              .whereType<int>()
              .where((i) => i >= 1 && i <= available.length)
              .toList();

      platformsToAdd = indices.map((i) => available[i - 1].id).toList();
    } else {
      // Direct mode — validate each ID
      platformsToAdd = [];
      for (final id in requestedIds) {
        if (PlatformRegistry.byId(id) == null) {
          stderr.writeln('Error: Unknown platform "$id".');
          stderr.writeln(
            'Available: ${PlatformRegistry.allPlatforms.map((p) => p.id).join(', ')}',
          );
          return;
        }
        if (forgeConfig.platforms.contains(id)) {
          print('  Platform "$id" is already enabled. Skipping.');
          continue;
        }
        platformsToAdd.add(id);
      }
    }

    if (platformsToAdd.isEmpty) {
      print('  No platforms to add.');
      return;
    }

    // Confirmation
    print('');
    print('  Platforms to add:');
    for (final id in platformsToAdd) {
      final info = PlatformRegistry.byId(id)!;
      print('    + ${info.displayName}');
    }
    print('');
    final confirm = PromptUtils.askYesNo('  Proceed?', defaultValue: true);
    if (!confirm) {
      print('  Cancelled.');
      return;
    }

    // Enable desktop/web platform support if needed
    print('');
    final configFlags = _platformConfigFlags(platformsToAdd);
    if (configFlags.isNotEmpty) {
      print('  [1/4] Enabling platform support in Flutter...');
      for (final flag in configFlags) {
        final result = await Process.run(
          'flutter',
          ['config', '--enable-$flag'],
          runInShell: true,
        );
        if (result.exitCode == 0) {
          print('    Enabled $flag');
        } else {
          stderr.writeln('    Warning: could not enable $flag');
        }
      }
    }

    // Execute: flutter create --platforms <new> .
    final step1 = configFlags.isNotEmpty ? 2 : 1;
    final totalSteps = configFlags.isNotEmpty ? 4 : 3;
    print('');
    print('  [$step1/$totalSteps] Adding platform files...');
    final createPlatforms =
        platformsToAdd.map((id) => PlatformRegistry.byId(id)!.id).join(',');

    print('  Running: flutter create --platforms $createPlatforms --org ${forgeConfig.org} .');
    print('');

    final process = await Process.start(
      'flutter',
      ['create', '--platforms', createPlatforms, '--org', forgeConfig.org, '.'],
      workingDirectory: projectPath,
      mode: ProcessStartMode.inheritStdio,
      runInShell: true,
    );

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      stderr.writeln('Error: flutter create failed.');
      return;
    }

    // Run pub get to resolve new platform dependencies
    print('');
    print('  [${step1 + 1}/$totalSteps] Resolving dependencies...');
    final pubGetResult = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: projectPath,
      runInShell: true,
    );
    if (pubGetResult.exitCode != 0) {
      stderr.writeln('Warning: flutter pub get had issues:');
      stderr.writeln(pubGetResult.stderr);
    }

    // Update config
    print('  [${step1 + 2}/$totalSteps] Updating project configuration...');
    final updatedConfig = forgeConfig.withPlatforms(platformsToAdd);
    await updatedConfig.save(projectPath);

    print('');
    print('  Platforms added successfully!');
    print('  Enabled: ${updatedConfig.platforms.join(', ')}');
    print('');
  }

  Future<void> _removePlatforms(
    String projectPath,
    ForgeConfig forgeConfig,
  ) async {
    final platforms = forgeConfig.platforms;

    if (platforms.isEmpty) {
      print('');
      print('  No platforms are enabled.');
      print('');
      return;
    }

    print('');
    print('  Enabled platforms:');
    for (var i = 0; i < platforms.length; i++) {
      final id = platforms[i];
      final info = PlatformRegistry.byId(id);
      final label = info?.displayName ?? id;
      print('    ${i + 1}) $label');
    }
    print('');

    final input = PromptUtils.askText(
      '  Enter platform numbers to remove (comma-separated)',
    );
    final indices =
        input
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .where((i) => i >= 1 && i <= platforms.length)
            .toList();

    final platformsToRemove = indices.map((i) => platforms[i - 1]).toList();

    if (platformsToRemove.isEmpty) {
      print('  No platforms selected.');
      return;
    }

    print('');
    print('  Platforms to remove:');
    for (final id in platformsToRemove) {
      final info = PlatformRegistry.byId(id)!;
      print('    - ${info.displayName}');
    }
    print('');
    stderr.writeln('  Warning: This will delete the platform directories.');
    final confirm = PromptUtils.askYesNo('  Proceed?', defaultValue: false);
    if (!confirm) {
      print('  Cancelled.');
      return;
    }

    // Delete platform directories
    print('');
    print('  [1/2] Removing platform directories...');
    for (final id in platformsToRemove) {
      final dir = Directory(p.join(projectPath, id));
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
        print('    Deleted $id/');
      }
    }

    // Update config
    print('  [2/2] Updating project configuration...');
    final updatedConfig = forgeConfig.withoutPlatforms(platformsToRemove);
    await updatedConfig.save(projectPath);

    print('');
    print('  Platforms removed successfully!');
    print('  Enabled: ${updatedConfig.platforms.join(', ')}');
    print('');
  }

  /// Returns the `flutter config` flag names needed for the given platforms.
  /// E.g. 'windows' → 'windows-desktop', 'web' → 'web'.
  static List<String> _platformConfigFlags(List<String> platformIds) {
    const flagMap = {
      'windows': 'windows-desktop',
      'macos': 'macos-desktop',
      'linux': 'linux-desktop',
      'web': 'web',
    };
    return platformIds
        .where((id) => flagMap.containsKey(id))
        .map((id) => flagMap[id]!)
        .toList();
  }
}
