import 'package:args/command_runner.dart';

import 'package:fluttermint/src/cli/prompts/wizard.dart';
import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/generator/project_generator.dart';
import 'package:fluttermint/src/modules/module_registry.dart';

class CreateCommand extends Command<void> {
  @override
  final String name = 'create';

  @override
  final String description =
      'Create a new Flutter project with pre-configured architecture.\n'
      'Usage: fluttermint create <app_name>   — quick create with defaults\n'
      '       fluttermint create              — interactive wizard';

  @override
  Future<void> run() async {
    final rest = argResults?.rest ?? [];

    ProjectConfig config;

    if (rest.isEmpty) {
      final wizard = Wizard();
      config = await wizard.run(null);
    } else {
      final appName = rest.first;

      if (!_isValidAppName(appName)) {
        print(
          'Error: "$appName" is not a valid app name.\n'
          'Use only lowercase letters, numbers, and underscores.',
        );
        return;
      }

      config = ProjectConfig(
        appName: appName,
        selectedModules: ModuleRegistry.defaultModuleIds,
      );
    }

    final generator = ProjectGenerator();
    await generator.generate(config);
  }

  bool _isValidAppName(String name) {
    return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name);
  }
}
