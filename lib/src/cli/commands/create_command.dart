import 'package:args/command_runner.dart';

import 'package:fluttermint/src/cli/prompts/prompt_utils.dart';
import 'package:fluttermint/src/cli/prompts/wizard.dart';
import 'package:fluttermint/src/config/design_pattern.dart';
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

      // Prompt for design pattern even in quick create
      print('');
      print('Select architecture pattern:');
      print('');
      final patternChoice = PromptUtils.askChoice(
        'Architecture pattern',
        [
          'MVVM (Model-View-ViewModel) — Provider + ChangeNotifier',
          'MVI (Model-View-Intent) — BLoC + Equatable',
          'MVVM + Riverpod — flutter_riverpod + AsyncNotifier',
        ],
      );
      final designPattern = switch (patternChoice) {
        2 => DesignPattern.mvi,
        3 => DesignPattern.riverpod,
        _ => DesignPattern.mvvm,
      };

      config = ProjectConfig(
        appName: appName,
        designPattern: designPattern,
        selectedModules:
            ModuleRegistry.defaultModuleIdsForPattern(designPattern),
      );
    }

    final generator = ProjectGenerator();
    await generator.generate(config);
  }

  bool _isValidAppName(String name) {
    return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name);
  }
}
