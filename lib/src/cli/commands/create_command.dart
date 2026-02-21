import 'package:args/command_runner.dart';

import 'package:flutterforge/src/config/project_config.dart';
import 'package:flutterforge/src/generator/project_generator.dart';
import 'package:flutterforge/src/modules/module_registry.dart';

class CreateCommand extends Command<void> {
  @override
  final String name = 'create';

  @override
  final String description =
      'Create a new Flutter project with pre-configured architecture.\n'
      'Usage: flutterforge create <app_name>   — quick create with defaults\n'
      '       flutterforge create              — interactive wizard';

  @override
  Future<void> run() async {
    final rest = argResults?.rest ?? [];

    ProjectConfig config;

    if (rest.isEmpty) {
      // TODO: Interactive wizard (Phase 4)
      print('Interactive wizard coming soon. Please provide an app name:');
      print('  flutterforge create <app_name>');
      return;
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
