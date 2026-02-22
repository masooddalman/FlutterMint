import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:flutterforge/src/config/forge_config.dart';
import 'package:flutterforge/src/config/project_config.dart';
import 'package:flutterforge/src/generator/file_writer.dart';
import 'package:flutterforge/src/generator/pubspec_editor.dart';
import 'package:flutterforge/src/generator/shared_file_composer.dart';
import 'package:flutterforge/src/modules/module.dart';
import 'package:flutterforge/src/modules/module_registry.dart';

class ModuleAdder {
  final FileWriter _fileWriter = FileWriter();
  final PubspecEditor _pubspecEditor = PubspecEditor();
  final SharedFileComposer _composer = SharedFileComposer();

  Future<void> add(
    String projectPath,
    ForgeConfig forgeConfig,
    List<String> newModuleIds,
  ) async {
    final stopwatch = Stopwatch()..start();

    // Compute full module set (existing + new), deduplicated
    final allModuleIds = {...forgeConfig.modules, ...newModuleIds}.toList();

    // Resolve all modules with topological sort
    final allModules = ModuleRegistry.resolveModules(allModuleIds);

    // Identify only the newly added modules (for file generation + deps)
    final newModules =
        allModules.where((m) => newModuleIds.contains(m.id)).toList();

    // Build ProjectConfig with ALL modules for shared file composition
    final projectConfig = ProjectConfig(
      appName: forgeConfig.appName,
      selectedModules: allModuleIds,
    );

    // Step 1: Add dependencies to pubspec.yaml (only new modules)
    _printStep(1, 'Adding dependencies...');
    await _pubspecEditor.addDependencies(projectPath, newModules);

    // Step 2: Generate module-specific files (skip existing)
    _printStep(2, 'Generating module files...');
    await _generateNewModuleFiles(projectPath, projectConfig, newModules);

    // Step 3: Regenerate shared files with ALL modules
    _printStep(3, 'Updating shared files (main.dart, app.dart, locator.dart)...');
    await _composer.compose(projectPath, projectConfig, allModules);

    // Step 4: Run flutter pub get
    _printStep(4, 'Resolving dependencies...');
    await _runPubGet(projectPath);

    // Step 5: Run gen-l10n if localization was just added
    if (newModuleIds.contains('localization')) {
      _printStep(5, 'Generating localization files...');
      await _runGenL10n(projectPath);
    }

    // Step 6: Update .flutterforge.yaml
    final updatedConfig = forgeConfig.withModules(newModuleIds);
    await updatedConfig.save(projectPath);

    stopwatch.stop();
    final seconds =
        (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);

    print('');
    print('=== Modules added successfully! ($seconds s) ===');
    print('');
    print('Added:');
    for (final module in newModules) {
      print('  + ${module.displayName}');
    }
    print('');
  }

  Future<void> _generateNewModuleFiles(
    String projectPath,
    ProjectConfig config,
    List<Module> newModules,
  ) async {
    for (final module in newModules) {
      final files = module.generateFiles(config);
      for (final entry in files.entries) {
        final filePath = p.join(projectPath, entry.key);
        // Skip if file already exists to avoid overwriting user changes
        if (await File(filePath).exists()) {
          print('    Skipping ${entry.key} (already exists)');
          continue;
        }
        if (entry.value.isNotEmpty) {
          await _fileWriter.write(filePath, entry.value);
        }
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

  Future<void> _runGenL10n(String projectPath) async {
    final result = await Process.run(
      'flutter',
      ['gen-l10n'],
      workingDirectory: projectPath,
      runInShell: true,
    );
    if (result.exitCode != 0) {
      stderr.writeln('Warning: flutter gen-l10n had issues:');
      stderr.writeln(result.stderr);
    }
  }
}
