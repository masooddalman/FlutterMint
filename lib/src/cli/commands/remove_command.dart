import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:fluttermint/src/cli/prompts/prompt_utils.dart';
import 'package:fluttermint/src/config/forge_config.dart';
import 'package:fluttermint/src/generator/module_remover.dart';
import 'package:fluttermint/src/modules/module.dart';
import 'package:fluttermint/src/modules/module_registry.dart';

class RemoveCommand extends Command<void> {
  @override
  final String name = 'remove';

  @override
  final String description = 'Remove a module from an existing FlutterMint project.';

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

    // 2. Find removable modules (installed but not default)
    final allModules = ModuleRegistry.allModules;
    final removableModules = allModules
        .where((m) => forgeConfig.modules.contains(m.id) && !m.isDefault)
        .toList();

    if (removableModules.isEmpty) {
      print('No removable modules found.');
      print('Default modules (mvvm, logging) cannot be removed.');
      return;
    }

    // 3. Get module IDs to remove
    final rest = argResults?.rest ?? [];
    List<String> moduleIdsToRemove;

    if (rest.isEmpty) {
      // Interactive mode
      moduleIdsToRemove = _interactiveSelect(removableModules);
      if (moduleIdsToRemove.isEmpty) {
        print('No modules selected.');
        return;
      }
    } else {
      // Direct mode
      final requestedId = rest.first;

      final module = allModules.where((m) => m.id == requestedId).firstOrNull;
      if (module == null) {
        stderr.writeln('Error: Unknown module "$requestedId".');
        stderr.writeln(
          'Installed modules: ${forgeConfig.modules.join(", ")}',
        );
        return;
      }

      if (!forgeConfig.modules.contains(requestedId)) {
        print('Module "$requestedId" is not installed.');
        return;
      }

      if (module.isDefault) {
        stderr.writeln(
          'Error: Cannot remove default module "$requestedId".',
        );
        stderr.writeln(
          'Default modules (mvvm, logging) are required for the project structure.',
        );
        return;
      }

      moduleIdsToRemove = [requestedId];
    }

    // 4. Reverse dependency resolution — find installed modules that depend
    //    on the ones being removed
    final resolvedIds = <String>[...moduleIdsToRemove];
    for (final installedId in forgeConfig.modules) {
      if (resolvedIds.contains(installedId)) continue;
      final installedModule = allModules.firstWhere((m) => m.id == installedId);
      // If this installed module depends on any module being removed, it must go too
      for (final depId in installedModule.dependsOn) {
        if (resolvedIds.contains(depId)) {
          resolvedIds.add(installedId);
          print('  Auto-including dependent: $installedId (depends on $depId)');
          break;
        }
      }
    }

    // 5. Confirmation
    print('');
    print('Modules to remove:');
    for (final id in resolvedIds) {
      final module = allModules.firstWhere((m) => m.id == id);
      print('  - ${module.displayName}');
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
    final remover = ModuleRemover();
    await remover.remove(projectPath, forgeConfig, resolvedIds);
  }

  List<String> _interactiveSelect(List<Module> removableModules) {
    print('');
    print('Installed modules (removable):');
    for (var i = 0; i < removableModules.length; i++) {
      print('  ${i + 1}. ${removableModules[i].displayName} (${removableModules[i].id})');
    }
    print('');

    final input = PromptUtils.askText(
      'Enter module name to remove (or "cancel" to abort)',
    );

    if (input.toLowerCase() == 'cancel') return [];

    final match = removableModules.where((m) => m.id == input).firstOrNull;
    if (match == null) {
      print('Unknown module "$input". Please enter a valid module id.');
      return _interactiveSelect(removableModules);
    }

    return [match.id];
  }
}
