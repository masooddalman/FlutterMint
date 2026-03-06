import 'package:fluttermint/src/config/design_pattern.dart';
import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/modules/module.dart';
import 'package:fluttermint/src/templates/services/database_template.dart';

class DatabaseModule extends Module {
  @override
  String get id => 'database';

  @override
  String get displayName => 'Local Database (sqflite)';

  @override
  bool get isDefault => false;

  @override
  List<String> get dependsOn => [];

  @override
  Map<String, String> get dependencies => {
        'sqflite': '^2.3.0',
        'path': '^1.9.0',
      };

  @override
  Map<String, String> get devDependencies => {};

  @override
  Map<String, String> generateFiles(ProjectConfig config) {
    final files = <String, String>{
      'lib/core/database/database_service.dart':
          DatabaseTemplate.generateDatabaseService(config),
    };

    if (config.designPattern == DesignPattern.riverpod) {
      files['lib/core/database/database_providers.dart'] =
          DatabaseTemplate.generateDatabaseProviders(config);
    }

    return files;
  }

  @override
  List<String> mainImports(ProjectConfig config) => [];

  @override
  List<String> mainSetupLines(ProjectConfig config) => [];

  @override
  List<String> mainProviderOverrides(ProjectConfig config) => [];

  @override
  List<String> locatorImports(ProjectConfig config) {
    if (config.designPattern != DesignPattern.riverpod &&
        config.hasModule('locator')) {
      return [
        'package:${config.appNameSnakeCase}/core/database/database_service.dart',
      ];
    }
    return [];
  }

  @override
  List<String> locatorRegistrations(ProjectConfig config) {
    if (config.designPattern != DesignPattern.riverpod &&
        config.hasModule('locator')) {
      return [
        'locator.registerLazySingleton<DatabaseService>(() => DatabaseService.instance);',
      ];
    }
    return [];
  }

  @override
  List<String> providerDeclarations(ProjectConfig config) => [];

  @override
  List<String> appImports(ProjectConfig config) => [];
}
