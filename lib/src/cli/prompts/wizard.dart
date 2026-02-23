import 'package:flutterforge/src/cli/prompts/prompt_utils.dart';
import 'package:flutterforge/src/config/project_config.dart';
import 'package:flutterforge/src/modules/module_registry.dart';

class Wizard {
  Future<ProjectConfig> run(String? providedName) async {
    PromptUtils.printHeader('FlutterForge Project Wizard');

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

    print('');
    print('Select optional modules to include:');
    print('');

    // Start with default modules
    final selectedModules = <String>[...ModuleRegistry.defaultModuleIds];
    final optionalModules = ModuleRegistry.optionalModules;

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

    print('');
    print('Project: $appName');
    print('Organization: $org');
    print('Package: $org.$appName');
    print('Modules: ${selectedModules.join(", ")}');
    print('');

    final confirm = PromptUtils.askYesNo('Proceed with creation?', defaultValue: true);
    if (!confirm) {
      print('Cancelled.');
      return run(null);
    }

    return ProjectConfig(
      appName: appName,
      org: org,
      selectedModules: selectedModules,
    );
  }
}
