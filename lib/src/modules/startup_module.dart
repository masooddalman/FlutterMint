import 'package:fluttermint/src/config/design_pattern.dart';
import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/modules/module.dart';
import 'package:fluttermint/src/templates/services/startup_template.dart';

class StartupModule extends Module {
  @override
  String get id => 'startup';

  @override
  String get displayName => 'Startup Flow';

  @override
  bool get isDefault => false;

  @override
  List<String> get dependsOn => [];

  @override
  Map<String, String> get dependencies => {};

  @override
  Map<String, String> get devDependencies => {};

  @override
  Map<String, String> generateFiles(ProjectConfig config) {
    if (config.designPattern == DesignPattern.mvi) {
      return {
        'lib/app/startup/startup_service.dart':
            StartupTemplate.generateStartupService(config),
        'lib/app/startup/startup_bloc.dart':
            StartupTemplate.generateStartupBloc(config),
        'lib/app/startup/startup_event.dart':
            StartupTemplate.generateStartupEvent(config),
        'lib/app/startup/startup_state.dart':
            StartupTemplate.generateStartupState(config),
        'lib/app/startup/startup_view.dart':
            StartupTemplate.generateStartupViewMvi(config),
      };
    }
    return {
      'lib/app/startup/startup_service.dart':
          StartupTemplate.generateStartupService(config),
      'lib/app/startup/startup_viewmodel.dart':
          StartupTemplate.generateStartupViewModel(config),
      'lib/app/startup/startup_view.dart':
          StartupTemplate.generateStartupView(config),
    };
  }

  @override
  List<String> mainImports(ProjectConfig config) => [];

  @override
  List<String> mainSetupLines(ProjectConfig config) => [];

  @override
  List<String> locatorImports(ProjectConfig config) {
    if (!config.hasModule('locator')) return [];
    if (config.designPattern == DesignPattern.mvi) {
      return [
        'package:${config.appNameSnakeCase}/app/startup/startup_service.dart',
        'package:${config.appNameSnakeCase}/app/startup/startup_bloc.dart',
      ];
    }
    return [
      'package:${config.appNameSnakeCase}/app/startup/startup_service.dart',
      'package:${config.appNameSnakeCase}/app/startup/startup_viewmodel.dart',
    ];
  }

  @override
  List<String> locatorRegistrations(ProjectConfig config) {
    if (!config.hasModule('locator')) return [];
    if (config.designPattern == DesignPattern.mvi) {
      return [
        'locator.registerLazySingleton<StartupService>(() => StartupService());',
        'locator.registerFactory(() => StartupBloc());',
      ];
    }
    return [
      'locator.registerLazySingleton<StartupService>(() => StartupService());',
      'locator.registerFactory(() => StartupViewModel());',
    ];
  }

  @override
  List<String> providerDeclarations(ProjectConfig config) => [];

  @override
  List<String> appImports(ProjectConfig config) => config.hasModule('routing')
      ? []
      : [
          'package:${config.appNameSnakeCase}/app/startup/startup_view.dart',
        ];
}
