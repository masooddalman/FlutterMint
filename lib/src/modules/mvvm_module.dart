import 'package:flutterforge/src/config/project_config.dart';
import 'package:flutterforge/src/modules/module.dart';
import 'package:flutterforge/src/templates/mvvm/home_feature_template.dart';
import 'package:flutterforge/src/templates/mvvm/usecase_template.dart';
import 'package:flutterforge/src/templates/mvvm/viewmodel_template.dart';

class MvvmModule extends Module {
  @override
  String get id => 'mvvm';

  @override
  String get displayName => 'MVVM Architecture';

  @override
  bool get isDefault => true;

  @override
  List<String> get dependsOn => [];

  @override
  Map<String, String> get dependencies => {
        'provider': '^6.1.0',
      };

  @override
  Map<String, String> get devDependencies => {};

  @override
  Map<String, String> generateFiles(ProjectConfig config) => {
        'lib/core/base/base_viewmodel.dart':
            ViewModelTemplate.generate(config),
        'lib/domain/repositories/home_repository.dart':
            UseCaseTemplate.generateHomeRepositoryInterface(config),
        'lib/data/repositories/home_repository.dart':
            UseCaseTemplate.generateHomeRepositoryImpl(config),
        'lib/domain/usecases/get_home_data_usecase.dart':
            UseCaseTemplate.generateGetHomeDataUseCase(config),
        'lib/features/home/models/home_model.dart':
            HomeFeatureTemplate.generateModel(config),
        'lib/features/home/viewmodels/home_viewmodel.dart':
            HomeFeatureTemplate.generateViewModel(config),
        'lib/features/home/views/home_view.dart':
            HomeFeatureTemplate.generateView(config),
      };

  @override
  List<String> mainImports(ProjectConfig config) => [];

  @override
  List<String> mainSetupLines(ProjectConfig config) => [];

  @override
  List<String> locatorImports(ProjectConfig config) => [
        'package:${config.appNameSnakeCase}/data/repositories/home_repository.dart',
        'package:${config.appNameSnakeCase}/domain/repositories/home_repository.dart',
        'package:${config.appNameSnakeCase}/domain/usecases/get_home_data_usecase.dart',
        'package:${config.appNameSnakeCase}/features/home/viewmodels/home_viewmodel.dart',
      ];

  @override
  List<String> locatorRegistrations(ProjectConfig config) => [
        'locator.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl());',
        'locator.registerLazySingleton(() => GetHomeDataUseCase(locator<HomeRepository>()));',
        'locator.registerFactory(() => HomeViewModel(locator<GetHomeDataUseCase>()));',
      ];

  @override
  List<String> providerDeclarations(ProjectConfig config) => [];

  @override
  List<String> appImports(ProjectConfig config) =>
      config.hasModule('routing')
          ? []
          : [
              'package:${config.appNameSnakeCase}/features/home/views/home_view.dart',
            ];
}
