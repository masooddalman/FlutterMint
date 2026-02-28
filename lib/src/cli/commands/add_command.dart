import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:fluttermint/src/cli/prompts/prompt_utils.dart';
import 'package:fluttermint/src/config/forge_config.dart';
import 'package:fluttermint/src/generator/module_adder.dart';
import 'package:fluttermint/src/modules/module.dart';
import 'package:fluttermint/src/modules/module_registry.dart';

class AddCommand extends Command<void> {
  @override
  final String name = 'add';

  @override
  final String description = 'Add a module to an existing FlutterMint project.';

  @override
  Future<void> run() async {
    final projectPath = Directory.current.path;

    // 1. Load existing config
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

    // 2. Find available modules (not yet installed)
    final allModules = ModuleRegistry.allModules;
    final availableModules =
        allModules.where((m) => !forgeConfig.modules.contains(m.id)).toList();

    if (availableModules.isEmpty) {
      print('All modules are already installed!');
      return;
    }

    // 3. Get module IDs to add
    final rest = argResults?.rest ?? [];
    List<String> moduleIdsToAdd;

    if (rest.isEmpty) {
      // Interactive mode
      moduleIdsToAdd = _interactiveSelect(availableModules, forgeConfig);
      if (moduleIdsToAdd.isEmpty) {
        print('No modules selected.');
        return;
      }
    } else {
      // Direct mode
      final requestedId = rest.first;

      final moduleExists = allModules.any((m) => m.id == requestedId);
      if (!moduleExists) {
        stderr.writeln('Error: Unknown module "$requestedId".');
        stderr.writeln(
          'Available modules: ${availableModules.map((m) => m.id).join(", ")}',
        );
        return;
      }

      if (forgeConfig.modules.contains(requestedId)) {
        print('Module "$requestedId" is already installed.');
        return;
      }

      moduleIdsToAdd = [requestedId];
    }

    // 4. Auto-resolve dependencies
    final resolvedIds = <String>[...moduleIdsToAdd];
    for (final id in moduleIdsToAdd) {
      final module = allModules.firstWhere((m) => m.id == id);
      for (final depId in module.dependsOn) {
        if (!forgeConfig.modules.contains(depId) &&
            !resolvedIds.contains(depId)) {
          resolvedIds.add(depId);
          print('  Auto-including dependency: $depId');
        }
      }
    }

    // 5. Confirmation
    print('');
    print('Modules to add:');
    for (final id in resolvedIds) {
      final module = allModules.firstWhere((m) => m.id == id);
      print('  + ${module.displayName}');
    }
    print('');
    print('Note: main.dart, app.dart, and locator.dart will be regenerated.');
    print('');
    final confirm = PromptUtils.askYesNo('Proceed?', defaultValue: true);
    if (!confirm) {
      print('Cancelled.');
      return;
    }

    // 6. Execute
    print('');
    final adder = ModuleAdder();
    await adder.add(projectPath, forgeConfig, resolvedIds);
  }

  List<String> _interactiveSelect(
    List<Module> availableModules,
    ForgeConfig forgeConfig,
  ) {
    print('');
    print('Available modules:');
    for (var i = 0; i < availableModules.length; i++) {
      final module = availableModules[i];
      final depInfo = module.dependsOn.isNotEmpty
          ? ' (requires: ${module.dependsOn.join(", ")})'
          : '';
      print('  ${i + 1}. ${module.displayName} (${module.id})$depInfo');
    }
    print('');

    final input = PromptUtils.askText(
      'Enter module name to add (or "cancel" to abort)',
    );

    if (input.toLowerCase() == 'cancel') return [];

    final match = availableModules.where((m) => m.id == input).firstOrNull;
    if (match == null) {
      print('Unknown module "$input". Please enter a valid module id.');
      return _interactiveSelect(availableModules, forgeConfig);
    }

    return [match.id];
  }
}
