import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:flutterforge/src/config/forge_config.dart';
import 'package:flutterforge/src/config/project_config.dart';
import 'package:flutterforge/src/generator/pubspec_editor.dart';
import 'package:flutterforge/src/generator/shared_file_composer.dart';
import 'package:flutterforge/src/modules/module.dart';
import 'package:flutterforge/src/modules/module_registry.dart';

class ModuleRemover {
  final PubspecEditor _pubspecEditor = PubspecEditor();
  final SharedFileComposer _composer = SharedFileComposer();

  Future<void> remove(
    String projectPath,
    ForgeConfig forgeConfig,
    List<String> moduleIdsToRemove,
  ) async {
    final stopwatch = Stopwatch()..start();

    // Compute remaining modules
    final remainingIds =
        forgeConfig.modules.where((id) => !moduleIdsToRemove.contains(id)).toList();
    final remainingModules = ModuleRegistry.resolveModules(remainingIds);

    // Resolve modules being removed
    final modulesToRemove = ModuleRegistry.allModules
        .where((m) => moduleIdsToRemove.contains(m.id))
        .toList();

    // Build ProjectConfig with remaining modules for shared file composition
    final projectConfig = ProjectConfig(
      appName: forgeConfig.appName,
      selectedModules: remainingIds,
      cicdConfig: forgeConfig.cicdConfig,
      flavorsConfig: moduleIdsToRemove.contains('flavors') ? null : forgeConfig.flavorsConfig,
    );

    // Step 1: Delete module-specific files
    _printStep(1, 'Removing module files...');
    await _deleteModuleFiles(projectPath, projectConfig, modulesToRemove);

    // Step 2: Remove unused dependencies from pubspec.yaml
    _printStep(2, 'Cleaning up dependencies...');
    await _removeUnusedDeps(projectPath, modulesToRemove, remainingModules);

    // Step 3: Regenerate shared files with remaining modules
    _printStep(3, 'Updating shared files (main.dart, app.dart, locator.dart)...');
    await _composer.compose(projectPath, projectConfig, remainingModules);

    // Step 4: If locator was removed, delete locator.dart
    if (moduleIdsToRemove.contains('locator') && !remainingIds.contains('locator')) {
      final locatorFile = File(p.join(projectPath, 'lib', 'app', 'locator.dart'));
      if (await locatorFile.exists()) {
        await locatorFile.delete();
        print('    Deleted lib/app/locator.dart');
      }
    }

    // Step 5: Run flutter pub get
    _printStep(4, 'Resolving dependencies...');
    await _runPubGet(projectPath);

    // Step 6: Update .flutterforge.yaml
    final updatedConfig = forgeConfig.withoutModules(moduleIdsToRemove);
    await updatedConfig.save(projectPath);

    stopwatch.stop();
    final seconds = (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);

    print('');
    print('=== Modules removed successfully! ($seconds s) ===');
    print('');
    print('Removed:');
    for (final module in modulesToRemove) {
      print('  - ${module.displayName}');
    }
    print('');
  }

  Future<void> _deleteModuleFiles(
    String projectPath,
    ProjectConfig config,
    List<Module> modulesToRemove,
  ) async {
    for (final module in modulesToRemove) {
      final files = module.generateFiles(config);
      for (final filePath in files.keys) {
        final file = File(p.join(projectPath, filePath));
        if (await file.exists()) {
          await file.delete();
          print('    Deleted $filePath');

          // Clean up empty parent directories
          await _cleanEmptyDirs(file.parent);
        }
      }
    }
  }

  Future<void> _cleanEmptyDirs(Directory dir) async {
    // Walk up the directory tree, deleting empty directories
    // Stop at lib/ or test/ level to avoid deleting project root dirs
    var current = dir;
    while (true) {
      final name = p.basename(current.path);
      if (name == 'lib' || name == 'test' || name == '.' || name == '..') break;

      if (!await current.exists()) break;

      final entries = await current.list().toList();
      if (entries.isEmpty) {
        await current.delete();
        current = current.parent;
      } else {
        break;
      }
    }
  }

  Future<void> _removeUnusedDeps(
    String projectPath,
    List<Module> modulesToRemove,
    List<Module> remainingModules,
  ) async {
    // Collect all deps still needed by remaining modules
    final neededDeps = <String>{};
    for (final module in remainingModules) {
      neededDeps.addAll(module.dependencies.keys);
      neededDeps.addAll(module.devDependencies.keys);
      neededDeps.addAll(module.sdkDependencies.keys);
    }

    // Collect deps from removed modules
    final removedDeps = <String>{};
    for (final module in modulesToRemove) {
      removedDeps.addAll(module.dependencies.keys);
      removedDeps.addAll(module.devDependencies.keys);
      removedDeps.addAll(module.sdkDependencies.keys);
    }

    // Only remove deps not needed by any remaining module
    final depsToRemove = removedDeps.difference(neededDeps);

    if (depsToRemove.isNotEmpty) {
      await _pubspecEditor.removeDependencies(projectPath, depsToRemove);
      for (final dep in depsToRemove) {
        print('    Removed dependency: $dep');
      }
    }
  }

  static void _printStep(int step, String message) {
    print('  [$step] $message');
  }

  Future<void> _runPubGet(String projectPath) async {
    final result = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: projectPath,
      runInShell: true,
    );
    if (result.exitCode != 0) {
      stderr.writeln('Warning: flutter pub get had issues:');
      stderr.writeln(result.stderr);
    }
  }
}
