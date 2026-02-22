import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:flutterforge/src/config/forge_config.dart';
import 'package:flutterforge/src/modules/module_registry.dart';

class StatusCommand extends Command<void> {
  @override
  final String name = 'status';

  @override
  final String description =
      'Show which modules are installed in the current FlutterForge project.';

  @override
  Future<void> run() async {
    final projectPath = Directory.current.path;

    final config = ForgeConfig.load(projectPath);
    if (config == null) {
      stderr.writeln(
        'Error: No FlutterForge project found in the current directory.',
      );
      stderr.writeln(
        'Make sure you are inside a project created with "flutterforge create".',
      );
      return;
    }

    print('');
    print('FlutterForge Project: ${config.appName}');
    print('');

    // Installed modules
    print('Installed modules:');
    final allModules = ModuleRegistry.allModules;
    final installedModules =
        allModules.where((m) => config.modules.contains(m.id)).toList();

    for (final module in installedModules) {
      final tag = module.isDefault ? ' (default)' : '';
      print('  + ${module.displayName}$tag');
    }

    // Available (not installed) modules
    final availableModules =
        allModules
            .where((m) => !config.modules.contains(m.id) && !m.isDefault)
            .toList();

    if (availableModules.isNotEmpty) {
      print('');
      print('Available modules (not installed):');
      for (final module in availableModules) {
        final deps =
            module.dependsOn.isNotEmpty
                ? ' (requires: ${module.dependsOn.join(", ")})'
                : '';
        print('  - ${module.id}: ${module.displayName}$deps');
      }
      print('');
      print('Add a module with: flutterforge add <module_id>');
    }

    print('');
  }
}
