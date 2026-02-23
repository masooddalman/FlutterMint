import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:flutterforge/src/cli/prompts/prompt_utils.dart';
import 'package:flutterforge/src/config/forge_config.dart';
import 'package:flutterforge/src/generator/screen_generator.dart';

class ScreenCommand extends Command<void> {
  ScreenCommand() {
    argParser.addMultiOption(
      'param',
      abbr: 'p',
      help: 'Route parameter in name:Type format (e.g. --param id:String).',
    );
  }

  @override
  final String name = 'screen';

  @override
  final String description =
      'Add a new screen to an existing FlutterForge project.\n'
      'Usage: flutterforge screen <screen_name> [--param name:Type]';

  @override
  Future<void> run() async {
    final projectPath = Directory.current.path;

    // Load existing config
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

    // Check MVVM module is installed
    if (!forgeConfig.modules.contains('mvvm')) {
      stderr.writeln('Error: The MVVM module is required to add screens.');
      stderr.writeln('Run "flutterforge add mvvm" first.');
      return;
    }

    // Get screen name
    final rest = argResults?.rest ?? [];
    String screenName;

    if (rest.isEmpty) {
      screenName = PromptUtils.askText(
        'Enter screen name (lowercase, underscores only)',
      );
    } else {
      screenName = rest.first;
    }

    // Validate
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(screenName)) {
      stderr.writeln('Error: "$screenName" is not a valid screen name.');
      stderr.writeln('Use only lowercase letters, numbers, and underscores.');
      return;
    }

    if (screenName == 'home') {
      stderr.writeln(
        'Error: "home" screen already exists as the default feature.',
      );
      return;
    }

    // Check if feature directory already exists
    final featureDir = Directory('$projectPath/lib/features/$screenName');
    if (await featureDir.exists()) {
      stderr.writeln('Error: Feature "$screenName" already exists.');
      return;
    }

    // Parse route params
    final rawParams = argResults?['param'] as List<String>? ?? [];
    final params = <String, String>{};
    for (final raw in rawParams) {
      final parts = raw.split(':');
      if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
        stderr.writeln('Error: Invalid param format "$raw".');
        stderr.writeln('Use name:Type format (e.g. --param id:String).');
        return;
      }
      params[parts[0]] = parts[1];
    }

    // Generate
    print('');
    final generator = ScreenGenerator();
    await generator.generate(
      projectPath,
      forgeConfig,
      screenName,
      params: params,
    );
  }
}
