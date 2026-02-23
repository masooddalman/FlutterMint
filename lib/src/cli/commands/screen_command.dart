import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:flutterforge/src/cli/prompts/prompt_utils.dart';
import 'package:flutterforge/src/config/forge_config.dart';
import 'package:flutterforge/src/generator/screen_generator.dart';

class ScreenCommand extends Command<void> {
  @override
  final String name = 'screen';

  @override
  final String description =
      'Add a new screen to an existing FlutterForge project.\n'
      'Usage: flutterforge screen <screen_name>';

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

    // Generate
    print('');
    final generator = ScreenGenerator();
    await generator.generate(projectPath, forgeConfig, screenName);
  }
}
