import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import 'package:flutterforge/src/cli/prompts/prompt_utils.dart';
import 'package:flutterforge/src/config/forge_config.dart';

class BuildCommand extends Command<void> {
  @override
  final String name = 'build';

  @override
  final String description =
      'Build the app with mode, flavor, and platform selection.';

  static const _platforms = [
    ('APK', 'apk'),
    ('App Bundle (AAB)', 'appbundle'),
    ('iOS (.app)', 'ios'),
  ];

  @override
  Future<void> run() async {
    final projectPath = Directory.current.path;

    final forgeConfig = ForgeConfig.load(projectPath);
    if (forgeConfig == null) {
      stderr.writeln(
        'Error: No FlutterForge project found in the current directory.',
      );
      stderr.writeln(
        'Make sure you are inside a project created with "flutterforge create".',
      );
      return;
    }

    final flutterArgs = <String>['build'];

    // 1. Build mode selection
    print('');
    print('  Select build mode:');
    print('    1) debug');
    print('    2) release (default)');
    print('');

    final modePick = PromptUtils.askText('  Build mode', defaultValue: '2');
    final isDebug = modePick == '1' || modePick.toLowerCase() == 'debug';
    final mode = isDebug ? 'debug' : 'release';
    print('  Using mode: $mode');

    // 2. Flavor / environment selection
    String? selectedEnv;
    if (forgeConfig.modules.contains('flavors') &&
        forgeConfig.flavorsConfig != null) {
      final flavorsConfig = forgeConfig.flavorsConfig!;
      final envs = flavorsConfig.environments;

      print('');
      print('  Select environment:');
      for (var i = 0; i < envs.length; i++) {
        final isDefault = envs[i].name == flavorsConfig.defaultEnvironment;
        final suffix = isDefault ? ' (default)' : '';
        print('    ${i + 1}) ${envs[i].name}$suffix');
      }
      print('');

      final defaultIdx = envs.indexWhere(
        (e) => e.name == flavorsConfig.defaultEnvironment,
      );
      final defaultStr = '${(defaultIdx >= 0 ? defaultIdx : 0) + 1}';

      final pick = PromptUtils.askText(
        '  Environment (number or name)',
        defaultValue: defaultStr,
      );

      // Support both number ("2") and name ("qa") input
      int selectedIdx;
      final idx = int.tryParse(pick);
      if (idx != null && idx >= 1 && idx <= envs.length) {
        selectedIdx = idx - 1;
      } else {
        final nameIdx = envs.indexWhere(
          (e) => e.name.toLowerCase() == pick.trim().toLowerCase(),
        );
        selectedIdx =
            nameIdx >= 0 ? nameIdx : (defaultIdx >= 0 ? defaultIdx : 0);
      }
      selectedEnv = envs[selectedIdx].name;
      print('  Using environment: $selectedEnv');
    }

    // 3. Platform selection
    print('');
    print('  Select platform:');
    for (var i = 0; i < _platforms.length; i++) {
      print('    ${i + 1}) ${_platforms[i].$1}');
    }
    print('');

    final platformPick = PromptUtils.askText('  Platform', defaultValue: '1');
    final platformIdx = int.tryParse(platformPick);
    final selectedPlatformIdx =
        (platformIdx != null &&
                platformIdx >= 1 &&
                platformIdx <= _platforms.length)
            ? platformIdx - 1
            : 0;
    final (platformLabel, platformSubcommand) = _platforms[selectedPlatformIdx];
    print('  Using platform: $platformLabel');

    final isAndroid =
        platformSubcommand == 'apk' || platformSubcommand == 'appbundle';

    // 4. APK: fat vs split-per-abi
    var splitPerAbi = false;
    if (platformSubcommand == 'apk') {
      print('');
      print('  Select APK type:');
      print('    1) Fat APK (all architectures in one file) (default)');
      print('    2) Split per ABI (separate APK per architecture)');
      print('');

      final abiPick = PromptUtils.askText('  APK type', defaultValue: '1');
      splitPerAbi = abiPick == '2' || abiPick.toLowerCase() == 'split';
      print('  Using: ${splitPerAbi ? 'Split per ABI' : 'Fat APK'}');
    }

    // 5. Android release signing check
    if (isAndroid && !isDebug) {
      final keyPropertiesFile = File(
        p.join(projectPath, 'android', 'key.properties'),
      );
      if (!keyPropertiesFile.existsSync()) {
        print('');
        stderr.writeln('  Warning: android/key.properties not found.');
        stderr.writeln(
          '  Release builds without signing configuration will use debug keys,',
        );
        stderr.writeln(
          '  which are not suitable for Google Play Store distribution.',
        );
        stderr.writeln('');
        stderr.writeln(
          '  To configure signing, create android/key.properties with:',
        );
        stderr.writeln('    storePassword=<password>');
        stderr.writeln('    keyPassword=<password>');
        stderr.writeln('    keyAlias=<alias>');
        stderr.writeln('    storeFile=<path/to/keystore.jks>');
        print('');

        final proceed = PromptUtils.askYesNo(
          '  Continue without signing?',
          defaultValue: false,
        );
        if (!proceed) {
          print('  Build cancelled.');
          return;
        }
      }
    }

    // 6. Build flutter args
    flutterArgs.add(platformSubcommand);
    flutterArgs.add('--$mode');

    if (splitPerAbi) {
      flutterArgs.add('--split-per-abi');
    }

    if (selectedEnv != null) {
      flutterArgs.add('--dart-define-from-file=config/$selectedEnv.json');
    }

    // 6. Execute
    print('');
    print('  Running: flutter ${flutterArgs.join(' ')}');
    print('');

    final process = await Process.start(
      'flutter',
      flutterArgs,
      workingDirectory: projectPath,
      mode: ProcessStartMode.inheritStdio,
      runInShell: true,
    );

    final exitCode = await process.exitCode;

    // 7. Post-build: rename output and print result
    if (exitCode == 0) {
      final version = _readVersion(projectPath);

      if (platformSubcommand == 'ios') {
        print('');
        print('  Build complete!');
        print('');
        print('  Next steps:');
        print('    1. Open the Xcode workspace:');
        print('       open ios/Runner.xcworkspace');
        print('    2. Select your target device or "Any iOS Device"');
        print(
          '    3. Product → Run (or Product → Archive for distribution)',
        );
        print('');
      } else {
        await _renameOutput(
          projectPath,
          forgeConfig.appName,
          platformSubcommand,
          mode,
          selectedEnv,
          version,
          splitPerAbi,
        );
      }
    }

    exit(exitCode);
  }

  /// Reads the version string from the project's pubspec.yaml.
  String _readVersion(String projectPath) {
    try {
      final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
      final lines = pubspecFile.readAsLinesSync();
      for (final line in lines) {
        final match = RegExp(r'^version:\s*(.+)').firstMatch(line);
        if (match != null) {
          // version may be "1.0.0+1", take only the semver part
          final full = match.group(1)!.trim();
          return full.split('+').first;
        }
      }
    } catch (_) {}
    return 'unknown';
  }

  /// Renames the Flutter build output to a descriptive filename.
  ///
  /// Pattern: `<appName>-<env>-<mode>-v<version>.apk/aab`
  /// Example: `my_app-staging-release-v1.2.0.apk`
  /// Split:   `my_app-staging-release-v1.2.0-arm64-v8a.apk`
  Future<void> _renameOutput(
    String projectPath,
    String appName,
    String platformSubcommand,
    String mode,
    String? env,
    String version,
    bool splitPerAbi,
  ) async {
    // Collect (sourceFile, abiTag) pairs to rename
    final filesToRename = <(File, String?)>[];

    if (platformSubcommand == 'apk') {
      final apkDir = p.join(
        projectPath,
        'build',
        'app',
        'outputs',
        'flutter-apk',
      );

      if (splitPerAbi) {
        const abis = ['armeabi-v7a', 'arm64-v8a', 'x86_64'];
        for (final abi in abis) {
          final file = File(p.join(apkDir, 'app-$abi-$mode.apk'));
          if (file.existsSync()) {
            filesToRename.add((file, abi));
          }
        }
      } else {
        final file = File(p.join(apkDir, 'app-$mode.apk'));
        filesToRename.add((file, null));
      }
    } else {
      // appbundle
      final file = File(
        p.join(
          projectPath,
          'build',
          'app',
          'outputs',
          'bundle',
          mode,
          'app-$mode.aab',
        ),
      );
      filesToRename.add((file, null));
    }

    final ext = platformSubcommand == 'apk' ? 'apk' : 'aab';

    print('');
    print('  Build complete!');

    for (final (sourceFile, abi) in filesToRename) {
      if (!sourceFile.existsSync()) continue;

      // Build descriptive filename
      final parts = <String>[appName];
      if (env != null) parts.add(env);
      parts.add(mode);
      parts.add('v$version');
      if (abi != null) parts.add(abi);
      final newName = '${parts.join('-')}.$ext';

      final destPath = p.join(sourceFile.parent.path, newName);
      final destFile = File(destPath);

      if (destFile.existsSync()) {
        destFile.deleteSync();
      }

      sourceFile.renameSync(destPath);

      final relativeDest =
          p.relative(destPath, from: projectPath).replaceAll(r'\', '/');

      print('    → $relativeDest');
    }

    print('');
  }
}
