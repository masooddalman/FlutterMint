import 'package:flutterforge/src/config/project_config.dart';
import 'package:flutterforge/src/modules/module.dart';
import 'package:flutterforge/src/templates/services/logger_template.dart';

class LoggingModule extends Module {
  @override
  String get id => 'logging';

  @override
  String get displayName => 'Logging Service';

  @override
  bool get isDefault => true;

  @override
  List<String> get dependsOn => [];

  @override
  Map<String, String> get dependencies => {};

  @override
  Map<String, String> get devDependencies => {};

  @override
  Map<String, String> generateFiles(ProjectConfig config) => {
        'lib/core/services/logger_service.dart':
            LoggerTemplate.generate(config),
      };

  @override
  List<String> mainImports(ProjectConfig config) => [];

  @override
  List<String> mainSetupLines(ProjectConfig config) => [];

  @override
  List<String> locatorImports(ProjectConfig config) => config.hasModule('locator')
      ? ['package:${config.appNameSnakeCase}/core/services/logger_service.dart']
      : [];

  @override
  List<String> locatorRegistrations(ProjectConfig config) =>
      config.hasModule('locator')
          ? ['locator.registerLazySingleton<LoggerService>(() => LoggerService());']
          : [];

  @override
  List<String> providerDeclarations(ProjectConfig config) => [];

  @override
  List<String> appImports(ProjectConfig config) => [];
}
