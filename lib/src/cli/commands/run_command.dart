import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:flutterforge/src/cli/prompts/prompt_utils.dart';
import 'package:flutterforge/src/config/forge_config.dart';

class RunCommand extends Command<void> {
  @override
  final String name = 'run';

  @override
  final String description = 'Run the app with optional flavor selection.';

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

    final flutterArgs = <String>['run'];

    // 1. Flavor / environment selection
    if (forgeConfig.modules.contains('flavors') &&
        forgeConfig.flavorsConfig != null) {
      final flavorsConfig = forgeConfig.flavorsConfig!;
      final envs = flavorsConfig.environments;

      print('');
      print('  Select environment:');
      for (var i = 0; i < envs.length; i++) {
        final isDefault =
            envs[i].name == flavorsConfig.defaultEnvironment;
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
      final selectedEnv = envs[selectedIdx].name;

      flutterArgs.add(
        '--dart-define-from-file=config/$selectedEnv.json',
      );

      print('  Using environment: $selectedEnv');
    }

    // 2. Device detection
    final devices = await _detectDevices();

    String? deviceId;
    if (devices == null) {
      // flutter devices --machine failed — let flutter handle device selection
      print('');
      print('  Could not detect devices. Flutter will select automatically.');
    } else if (devices.isEmpty) {
      stderr.writeln('');
      stderr.writeln('  No connected devices found.');
      stderr.writeln(
        '  Connect a device or start an emulator, then try again.',
      );
      return;
    } else if (devices.length == 1) {
      deviceId = devices.first['id'] as String;
      final name = devices.first['name'] as String;
      print('');
      print('  Device: $name ($deviceId)');
    } else {
      // Multiple devices — let user pick
      print('');
      print('  Select device:');
      for (var i = 0; i < devices.length; i++) {
        final d = devices[i];
        final name = d['name'] as String;
        final platform = d['targetPlatform'] as String? ?? '';
        final isEmulator = d['emulator'] == true;
        final tag = isEmulator ? ' [emulator]' : '';
        print('    ${i + 1}) $name ($platform)$tag');
      }
      print('');

      final pick = PromptUtils.askText('  Device', defaultValue: '1');
      final idx = int.tryParse(pick);
      final selectedIdx =
          (idx != null && idx >= 1 && idx <= devices.length) ? idx - 1 : 0;
      deviceId = devices[selectedIdx]['id'] as String;
    }

    if (deviceId != null) {
      flutterArgs.addAll(['-d', deviceId]);
    }

    // 3. Run flutter
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
    exit(exitCode);
  }

  Future<List<Map<String, dynamic>>?> _detectDevices() async {
    try {
      final result = await Process.run(
        'flutter',
        ['devices', '--machine'],
        runInShell: true,
      );

      if (result.exitCode != 0) return null;

      final output = (result.stdout as String).trim();
      // The output may contain non-JSON lines before the JSON array
      final jsonStart = output.indexOf('[');
      if (jsonStart < 0) return null;

      final jsonStr = output.substring(jsonStart);
      final decoded = jsonDecode(jsonStr) as List<dynamic>;

      return decoded
          .cast<Map<String, dynamic>>()
          .where((d) => d['isSupported'] == true)
          .toList();
    } catch (_) {
      return null;
    }
  }
}
