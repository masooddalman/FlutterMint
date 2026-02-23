import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:flutterforge/src/config/forge_config.dart';
import 'package:flutterforge/src/config/project_config.dart';
import 'package:flutterforge/src/generator/file_writer.dart';
import 'package:flutterforge/src/templates/mvvm/screen_template.dart';

class ScreenGenerator {
  final FileWriter _fileWriter = FileWriter();

  Future<void> generate(
    String projectPath,
    ForgeConfig forgeConfig,
    String screenName,
  ) async {
    final config = ProjectConfig(
      appName: forgeConfig.appName,
      org: forgeConfig.org,
      selectedModules: forgeConfig.modules,
      cicdConfig: forgeConfig.cicdConfig,
    );
    final pascal = ProjectConfig.toPascalCase(screenName);

    // Step 1: Generate feature files
    _printStep(1, 'Generating $screenName screen files...');
    final files = {
      'lib/features/$screenName/models/${screenName}_model.dart':
          ScreenTemplate.generateModel(screenName, config),
      'lib/features/$screenName/viewmodels/${screenName}_viewmodel.dart':
          ScreenTemplate.generateViewModel(screenName, config),
      'lib/features/$screenName/views/${screenName}_view.dart':
          ScreenTemplate.generateView(screenName, config),
      'lib/domain/repositories/${screenName}_repository.dart':
          ScreenTemplate.generateRepository(screenName, config),
      'lib/data/repositories/${screenName}_repository.dart':
          ScreenTemplate.generateRepositoryImpl(screenName, config),
      'lib/domain/usecases/get_${screenName}_data_usecase.dart':
          ScreenTemplate.generateUseCase(screenName, config),
      'lib/features/$screenName/widgets/.gitkeep': '',
    };

    var filesCreated = 0;
    for (final entry in files.entries) {
      final filePath = p.join(projectPath, entry.key);
      if (await File(filePath).exists()) {
        print('    Skipping ${entry.key} (already exists)');
        continue;
      }
      await _fileWriter.write(filePath, entry.value);
      filesCreated++;
    }

    // Step 2: Inject into locator.dart
    if (forgeConfig.modules.contains('locator')) {
      _printStep(2, 'Updating locator.dart...');
      await _injectLocator(projectPath, config, screenName, pascal);
    } else {
      _printStep(2, 'Skipping locator (module not installed)');
    }

    // Step 3: Inject into app_router.dart
    if (forgeConfig.modules.contains('routing')) {
      _printStep(3, 'Updating app_router.dart...');
      await _injectRouter(projectPath, config, screenName, pascal);
    } else {
      _printStep(3, 'Skipping router (module not installed)');
    }

    print('');
    print('=== Screen "$screenName" created ($filesCreated files) ===');
    print('');
    print('Generated:');
    print('  + features/$screenName/models/${screenName}_model.dart');
    print('  + features/$screenName/viewmodels/${screenName}_viewmodel.dart');
    print('  + features/$screenName/views/${screenName}_view.dart');
    print('  + features/$screenName/widgets/');
    print('  + domain/repositories/${screenName}_repository.dart');
    print('  + data/repositories/${screenName}_repository.dart');
    print('  + domain/usecases/get_${screenName}_data_usecase.dart');
    if (forgeConfig.modules.contains('locator')) {
      print('  ~ app/locator.dart (updated)');
    }
    if (forgeConfig.modules.contains('routing')) {
      print('  ~ core/routing/app_router.dart (updated)');
      print('');
      print('Route: RoutePaths.$screenName -> /$screenName');
    }
    print('');
  }

  Future<void> _injectLocator(
    String projectPath,
    ProjectConfig config,
    String name,
    String pascal,
  ) async {
    final locatorPath = p.join(projectPath, 'lib', 'app', 'locator.dart');
    final file = File(locatorPath);
    if (!await file.exists()) return;

    var content = await file.readAsString();
    final pkg = config.appNameSnakeCase;

    // Check if already injected
    if (content.contains('${pascal}Repository')) return;

    // Build new imports
    final newImports = [
      "import 'package:$pkg/data/repositories/${name}_repository.dart';",
      "import 'package:$pkg/domain/repositories/${name}_repository.dart';",
      "import 'package:$pkg/domain/usecases/get_${name}_data_usecase.dart';",
      "import 'package:$pkg/features/$name/viewmodels/${name}_viewmodel.dart';",
    ];

    // Build new registrations
    final newRegistrations = [
      '  locator.registerLazySingleton<${pascal}Repository>(() => ${pascal}RepositoryImpl());',
      '  locator.registerLazySingleton(() => Get${pascal}DataUseCase(locator<${pascal}Repository>()));',
      '  locator.registerFactory(() => ${pascal}ViewModel(locator<Get${pascal}DataUseCase>()));',
    ];

    // Find the last import line and insert after it
    final lines = content.split('\n');
    var lastImportIndex = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('import ')) {
        lastImportIndex = i;
      }
    }
    if (lastImportIndex >= 0) {
      lines.insertAll(lastImportIndex + 1, newImports);
    }

    // Find closing } of setupLocator() and insert before it
    content = lines.join('\n');
    final closingIndex = content.lastIndexOf('}');
    if (closingIndex >= 0) {
      content = '${content.substring(0, closingIndex)}'
          '${newRegistrations.join('\n')}\n'
          '${content.substring(closingIndex)}';
    }

    await file.writeAsString(content);
  }

  Future<void> _injectRouter(
    String projectPath,
    ProjectConfig config,
    String name,
    String pascal,
  ) async {
    final routerPath =
        p.join(projectPath, 'lib', 'core', 'routing', 'app_router.dart');
    final file = File(routerPath);
    if (!await file.exists()) return;

    var content = await file.readAsString();
    final pkg = config.appNameSnakeCase;

    // Check if already injected
    if (content.contains('${pascal}View')) return;

    // Add import after existing imports
    final newImport =
        "import 'package:$pkg/features/$name/views/${name}_view.dart';";
    final lines = content.split('\n');
    var lastImportIndex = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('import ')) {
        lastImportIndex = i;
      }
    }
    if (lastImportIndex >= 0) {
      lines.insert(lastImportIndex + 1, newImport);
    }
    content = lines.join('\n');

    // Add path constant before "// Add more paths here"
    const pathMarker = '// Add more paths here';
    final newPath = "  static const $name = '/$name';\n  $pathMarker";
    content = content.replaceFirst(pathMarker, newPath);

    // Add route before "// Add more routes here"
    const routeMarker = '// Add more routes here';
    final newRoute = '''      GoRoute(
        path: RoutePaths.$name,
        name: '$name',
        builder: (context, state) => const ${pascal}View(),
      ),
      $routeMarker''';
    content = content.replaceFirst(routeMarker, newRoute);

    await file.writeAsString(content);
  }

  static void _printStep(int step, String message) {
    print('  [$step] $message');
  }
}
