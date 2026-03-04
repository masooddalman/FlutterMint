import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:fluttermint/src/config/forge_config.dart';
import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/generator/file_writer.dart';
import 'package:fluttermint/src/generator/platform_configurator.dart';
import 'package:fluttermint/src/generator/pubspec_editor.dart';
import 'package:fluttermint/src/generator/shared_file_composer.dart';
import 'package:fluttermint/src/modules/module.dart';
import 'package:fluttermint/src/modules/module_registry.dart';

class ProjectGenerator {
  final FileWriter _fileWriter = FileWriter();
  final PubspecEditor _pubspecEditor = PubspecEditor();
  final SharedFileComposer _composer = SharedFileComposer();

  Future<void> generate(ProjectConfig config) async {
    final projectPath = p.join(Directory.current.path, config.appName);

    // Pre-flight check: is Flutter available?
    if (!await _isFlutterAvailable()) {
      stderr.writeln('Error: Flutter SDK not found on PATH.');
      stderr.writeln('Install Flutter: https://docs.flutter.dev/get-started/install');
      return;
    }

    // Check if directory already exists
    if (await Directory(projectPath).exists()) {
      stderr.writeln(
        'Error: Directory "${config.appName}" already exists.',
      );
      return;
    }

    final stopwatch = Stopwatch()..start();

    // Step 0: Enable desktop/web platform support if needed
    await _enablePlatformSupport(config.platforms);

    // Step 1: Run flutter create
    _printStep(1, 'Creating Flutter project...');
    await _runFlutterCreate(config.appName, config.org, config.platforms);

    // Step 2: Resolve and order selected modules
    final modules = ModuleRegistry.resolveModules(config.selectedModules);

    // Step 3: Clean up default flutter create files we'll replace
    await _cleanDefaults(projectPath);

    // Step 4: Add dependencies to pubspec.yaml
    _printStep(2, 'Configuring dependencies...');
    await _pubspecEditor.addDependencies(projectPath, modules);

    // Step 5: Generate module-specific files
    _printStep(3, 'Generating project structure...');
    await _generateModuleFiles(projectPath, config, modules);

    // Step 6: Compose shared files (main.dart, app.dart, locator.dart)
    _printStep(4, 'Composing application files...');
    await _composer.compose(projectPath, config, modules);

    // Step 7: Configure platform files
    if (config.hasModule('api') || config.hasModule('flavors')) {
      _printStep(5, 'Configuring platform files...');
      if (config.hasModule('api')) {
        await PlatformConfigurator.addAndroidPermissions(projectPath, [
          'android.permission.INTERNET',
          'android.permission.ACCESS_NETWORK_STATE',
        ]);
      }
      if (config.hasModule('flavors')) {
        await PlatformConfigurator.configureFlavorsAndroid(
          projectPath,
          config.appName,
        );
        await PlatformConfigurator.configureFlavorsIos(
          projectPath,
          config.appName,
        );
      }
    }

    // Step 8: Generate analysis_options.yaml
    await _generateAnalysisOptions(projectPath);

    // Step 9: Run flutter pub get
    _printStep(6, 'Resolving dependencies...');
    await _runPubGet(projectPath);

    // Step 10: Generate localization files if needed
    if (config.hasModule('localization')) {
      _printStep(7, 'Generating localization files...');
      await _runGenL10n(projectPath);
    }

    // Step 11: Write .fluttermint.yaml config
    final forgeConfig = ForgeConfig(
      appName: config.appName,
      org: config.org,
      designPattern: config.designPattern,
      modules: config.selectedModules,
      flavorsConfig: config.flavorsConfig,
      platforms: config.platforms,
    );
    await forgeConfig.save(projectPath);

    stopwatch.stop();
    final seconds = (stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(1);

    print('');
    print('=== Project "${config.appName}" created successfully! ($seconds s) ===');
    print('');
    print('Modules included:');
    for (final module in modules) {
      print('  + ${module.displayName}');
    }
    print('');
    print('Next steps:');
    print('  cd ${config.appName}');
    print('  flutter run');
    print('');
  }

  static void _printStep(int step, String message) {
    print('  [$step] $message');
  }

  Future<bool> _isFlutterAvailable() async {
    try {
      final result = await Process.run(
        'flutter',
        ['--version'],
        runInShell: true,
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> _enablePlatformSupport(List<String> platforms) async {
    const flagMap = {
      'windows': 'windows-desktop',
      'macos': 'macos-desktop',
      'linux': 'linux-desktop',
      'web': 'web',
    };
    for (final id in platforms) {
      final flag = flagMap[id];
      if (flag != null) {
        await Process.run('flutter', ['config', '--enable-$flag'], runInShell: true);
      }
    }
  }

  Future<void> _runFlutterCreate(String appName, String org, List<String> platforms) async {
    final result = await Process.run(
      'flutter',
      ['create', '--platforms', platforms.join(','), '--org', org, appName],
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
