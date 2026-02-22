import 'package:flutterforge/src/config/project_config.dart';
import 'package:flutterforge/src/modules/module.dart';
import 'package:flutterforge/src/templates/services/startup_template.dart';

class StartupModule extends Module {
  @override
  String get id => 'startup';

  @override
  String get displayName => 'Startup Flow';

  @override
  bool get isDefault => false;

  @override
  List<String> get dependsOn => ['mvvm'];

  @override
  Map<String, String> get dependencies => {};

  @override
  Map<String, String> get devDependencies => {};

  @override
  Map<String, String> generateFiles(ProjectConfig config) => {
        'lib/app/startup/startup_service.dart':
            StartupTemplate.generateStartupService(config),
        'lib/app/startup/startup_viewmodel.dart':
            StartupTemplate.generateStartupViewModel(config),
        'lib/app/startup/startup_view.dart':
            StartupTemplate.generateStartupView(config),
      };

  @override
  List<String> mainImports(ProjectConfig config) => [];

  @override
  List<String> mainSetupLines(ProjectConfig config) => [];

  @override
  List<String> locatorImports(ProjectConfig config) => config.hasModule('locator')
      ? ['package:${config.appNameSnakeCase}/app/startup/startup_service.dart']
      : [];

  @override
  List<String> locatorRegistrations(ProjectConfig config) =>
      config.hasModule('locator')
          ? ['locator.registerLazySingleton<StartupService>(() => StartupService());']
          : [];

  @override
  List<String> providerDeclarations(ProjectConfig config) => [];

  @override
  List<String> appImports(ProjectConfig config) => [];
}
