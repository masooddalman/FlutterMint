import 'package:fluttermint/src/cli/prompts/prompt_utils.dart';
import 'package:fluttermint/src/config/design_pattern.dart';
import 'package:fluttermint/src/config/flavors_config.dart';
import 'package:fluttermint/src/config/platform_config.dart';
import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/modules/module_registry.dart';

class Wizard {
  Future<ProjectConfig> run(String? providedName) async {
    PromptUtils.printHeader('FlutterMint Project Wizard');

    // Ask for app name if not provided
    final appName = providedName ??
        PromptUtils.askText(
          'Enter app name (lowercase, underscores only)',
        );

    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(appName)) {
      print('Error: "$appName" is not a valid app name.');
      print('Use only lowercase letters, numbers, and underscores.');
      return run(null);
    }

    final org = PromptUtils.askText(
      'Organization (reverse domain, e.g. com.mycompany)',
      defaultValue: 'com.example',
    );

    if (!RegExp(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$').hasMatch(org)) {
      print('Error: "$org" is not a valid organization.');
      print('Use reverse domain notation (e.g. com.mycompany).');
      return run(null);
    }

    // Design pattern selection
    print('');
    print('Select architecture pattern:');
    print('');
    final patternChoice = PromptUtils.askChoice(
      'Architecture pattern',
      [
        'MVVM (Model-View-ViewModel) — Provider + ChangeNotifier',
        'MVI (Model-View-Intent) — BLoC + Equatable',
      ],
    );
    final designPattern =
        patternChoice == 2 ? DesignPattern.mvi : DesignPattern.mvvm;

    print('');
    print('Select optional modules to include:');
    print('');

    // Start with default modules for the chosen pattern
    final selectedModules = <String>[
      ...ModuleRegistry.defaultModuleIdsForPattern(designPattern),
    ];
    final optionalModules =
        ModuleRegistry.optionalModulesForPattern(designPattern);

    for (var i = 0; i < optionalModules.length; i++) {
      final module = optionalModules[i];
      PromptUtils.printStep(i + 1, optionalModules.length, module.displayName);
      final include = PromptUtils.askYesNo('  Include ${module.displayName}?');
      if (include) {
        selectedModules.add(module.id);
        // Auto-include dependencies
        for (final depId in module.dependsOn) {
          if (!selectedModules.contains(depId)) {
            selectedModules.add(depId);
            print('    (auto-included dependency: $depId)');
          }
        }
      }
    }

    // Platform selection
    print('');
    print('Platforms (Android and iOS are included by default):');
    print('');

    final selectedPlatforms = <String>[...PlatformRegistry.defaultPlatformIds];
    final optionalPlatforms = PlatformRegistry.optionalPlatforms;

    for (var i = 0; i < optionalPlatforms.length; i++) {
      final platform = optionalPlatforms[i];
      PromptUtils.printStep(
        i + 1,
        optionalPlatforms.length,
        platform.displayName,
      );
      final include =
          PromptUtils.askYesNo('  Enable ${platform.displayName}?');
      if (include) {
        selectedPlatforms.add(platform.id);
      }
    }

    // If flavors was selected, run inline configuration
    FlavorsConfig? flavorsConfig;
    if (selectedModules.contains('flavors')) {
      flavorsConfig = _configureFlavors();
    }

    print('');
    print('Project: $appName');
    print('Organization: $org');
    print('Package: $org.$appName');
    print('Architecture: ${designPattern.displayName}');
    print('Platforms: ${selectedPlatforms.join(", ")}');
    print('Modules: ${selectedModules.join(", ")}');
    if (flavorsConfig != null) {
      print('Environments: ${flavorsConfig.environments.map((e) => e.name).join(", ")}');
    }
    print('');

    final confirm = PromptUtils.askYesNo('Proceed with creation?', defaultValue: true);
    if (!confirm) {
      print('Cancelled.');
      return run(null);
    }

    return ProjectConfig(
      appName: appName,
      org: org,
      designPattern: designPattern,
      selectedModules: selectedModules,
      flavorsConfig: flavorsConfig,
      platforms: selectedPlatforms,
    );
  }

  FlavorsConfig _configureFlavors() {
    print('');
    print('  Configure environments:');
    print('');

    final envNamesInput = PromptUtils.askText(
      '  Environment names (comma-separated)',
      defaultValue: 'dev, staging, production',
    );

    final envNames = envNamesInput
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty && RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(s))
        .toList();

    if (envNames.isEmpty) {
      print('  No valid environment names. Using defaults.');
      return FlavorsConfig.defaults;
    }

    final environments = <EnvironmentConfig>[];
    for (final name in envNames) {
      print('');
      print('  ── $name ──');
      final apiUrl = PromptUtils.askText(
        '    API base URL',
        defaultValue: 'https://$name-api.example.com',
      );
      final appNameSuffix = PromptUtils.askText(
        '    App name suffix (e.g. " Dev")',
        defaultValue: name == envNames.last ? '' : ' ${name[0].toUpperCase()}${name.substring(1)}',
      );
      final appIdSuffix = PromptUtils.askText(
        '    App ID suffix (e.g. ".dev")',
        defaultValue: name == envNames.last ? '' : '.$name',
      );

      // Custom key-value pairs
      final custom = <String, String>{};
      final wantCustom = PromptUtils.askYesNo('    Add custom config keys?');
      if (wantCustom) {
        while (true) {
          final key = PromptUtils.askText(
            '      Key (or "done" to finish)',
          );
          if (key.toLowerCase() == 'done') break;
          final value = PromptUtils.askText('      Value');
          custom[key] = value;
        }
      }

      environments.add(EnvironmentConfig(
        name: name,
        apiBaseUrl: apiUrl,
        appNameSuffix: appNameSuffix,
        appIdSuffix: appIdSuffix,
        custom: custom,
      ));
    }

    // Default environment
    final defaultEnv = PromptUtils.askText(
      '  Default environment (used in main.dart)',
      defaultValue: envNames.last,
    );

    return FlavorsConfig(
      environments: environments,
      defaultEnvironment: envNames.contains(defaultEnv) ? defaultEnv : envNames.last,
    );
  }
}
