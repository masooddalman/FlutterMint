import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:fluttermint/src/cli/prompts/prompt_utils.dart';
import 'package:fluttermint/src/config/forge_config.dart';
import 'package:fluttermint/src/generator/preference_generator.dart';

class PreferenceCommand extends Command<void> {
  PreferenceCommand() {
    addSubcommand(_PrefAddCommand());
  }

  @override
  final String name = 'pref';

  @override
  final String description = 'Manage typed preference accessors.';
}

class _PrefAddCommand extends Command<void> {
  _PrefAddCommand() {
    argParser.addOption(
      'type',
      abbr: 't',
      help: 'Value type: String, int, double, bool, List<String>',
    );
  }

  @override
  final String name = 'add';

  @override
  final String description =
      'Add a typed preference accessor to PreferencesService.\n'
      'Usage: fluttermint pref add <name> --type <type>\n'
      'Example: fluttermint pref add userEmail --type String';

  @override
  Future<void> run() async {
    final projectPath = Directory.current.path;

    // Load existing config
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

    // Check preferences module is installed
    if (!forgeConfig.modules.contains('preferences')) {
      stderr.writeln(
        'Error: Preferences module is not installed.',
      );
      stderr.writeln('Run "fluttermint add preferences" first.');
      return;
    }

    // Get preference name
    final rest = argResults?.rest ?? [];
    String prefName;

    if (rest.isEmpty) {
      prefName = PromptUtils.askText(
        'Enter preference name (camelCase, e.g. userEmail)',
      );
    } else {
      prefName = rest.first;
    }

    // Validate name
    if (!RegExp(r'^[a-z][a-zA-Z0-9]*$').hasMatch(prefName)) {
      stderr.writeln('Error: "$prefName" is not a valid preference name.');
      stderr.writeln('Use camelCase (e.g. userEmail, isDarkMode, fontSize).');
      return;
    }

    // Get type
    final supportedTypes = PreferenceGenerator.supportedTypes;
    var type = argResults?['type'] as String?;

    if (type == null) {
      final choice = PromptUtils.askChoice(
        'Select value type',
        supportedTypes,
      );
      type = supportedTypes[choice - 1];
    }

    // Generate
    print('');
    final generator = PreferenceGenerator();
    final success = await generator.generate(projectPath, prefName, type);

    if (success) {
      print('  Added preference: $prefName ($type)');
      print('');
      print('Usage:');
      print('  // Read');
      print('  final value = preferencesService.$prefName;');
      print('');
      print('  // Write');
      print('  preferencesService.$prefName = newValue;');
      print('');
    }
  }
}
