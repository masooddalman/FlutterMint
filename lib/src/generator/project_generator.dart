import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:flutterforge/src/config/project_config.dart';
import 'package:flutterforge/src/generator/file_writer.dart';
import 'package:flutterforge/src/generator/pubspec_editor.dart';
import 'package:flutterforge/src/generator/shared_file_composer.dart';
import 'package:flutterforge/src/modules/module.dart';
import 'package:flutterforge/src/modules/module_registry.dart';

class ProjectGenerator {
  final FileWriter _fileWriter = FileWriter();
  final PubspecEditor _pubspecEditor = PubspecEditor();
  final SharedFileComposer _composer = SharedFileComposer();

  Future<void> generate(ProjectConfig config) async {
    final projectPath = p.join(Directory.current.path, config.appName);

    // Check if directory already exists
    if (await Directory(projectPath).exists()) {
      stderr.writeln(
        'Error: Directory "${config.appName}" already exists.',
      );
      return;
    }

    // Step 1: Run flutter create
    print('Running flutter create ${config.appName}...');
    await _runFlutterCreate(config.appName);

    // Step 2: Resolve and order selected modules
    final modules = ModuleRegistry.resolveModules(config.selectedModules);

    // Step 3: Clean up default flutter create files we'll replace
    await _cleanDefaults(projectPath);

    // Step 4: Add dependencies to pubspec.yaml
    print('Configuring dependencies...');
    await _pubspecEditor.addDependencies(projectPath, modules);

    // Step 5: Generate module-specific files
    print('Generating project structure...');
    await _generateModuleFiles(projectPath, config, modules);

    // Step 6: Compose shared files (main.dart, app.dart, locator.dart)
    print('Composing application files...');
    await _composer.compose(projectPath, config, modules);

    // Step 7: Generate analysis_options.yaml
    await _generateAnalysisOptions(projectPath);

    // Step 8: Run flutter pub get
    print('Resolving dependencies...');
    await _runPubGet(projectPath);

    print('');
    print('Project "${config.appName}" created successfully!');
    print('');
    print('Next steps:');
    print('  cd ${config.appName}');
    print('  flutter run');
  }

  Future<void> _runFlutterCreate(String appName) async {
    final result = await Process.run(
      'flutter',
      ['create', '--org', 'com.example', appName],
      runInShell: true,
    );
    if (result.exitCode != 0) {
      throw Exception('flutter create failed:\n${result.stderr}');
    }
  }

  Future<void> _cleanDefaults(String projectPath) async {
    // Remove default test file that flutter create generates
    await _fileWriter.deleteFile(
      p.join(projectPath, 'test', 'widget_test.dart'),
    );
  }

  Future<void> _generateModuleFiles(
    String projectPath,
    ProjectConfig config,
    List<Module> modules,
  ) async {
    for (final module in modules) {
      final files = module.generateFiles(config);
      for (final entry in files.entries) {
        if (entry.value.isNotEmpty) {
          await _fileWriter.write(
            p.join(projectPath, entry.key),
            entry.value,
          );
        }
      }
    }
  }

  Future<void> _generateAnalysisOptions(String projectPath) async {
    const content = '''include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_single_quotes: true
    sort_constructors_first: true
    prefer_final_locals: true
''';
    await _fileWriter.write(
      p.join(projectPath, 'analysis_options.yaml'),
      content,
    );
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
