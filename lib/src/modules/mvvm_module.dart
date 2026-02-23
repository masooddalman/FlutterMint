import 'package:flutterforge/src/config/project_config.dart';
import 'package:flutterforge/src/modules/module.dart';
import 'package:flutterforge/src/templates/mvvm/screen_template.dart';
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

  static const _home = 'home';

  @override
  Map<String, String> generateFiles(ProjectConfig config) => {
        'lib/core/base/base_viewmodel.dart':
            ViewModelTemplate.generate(config),
        'lib/domain/repositories/home_repository.dart':
            ScreenTemplate.generateRepository(_home, config),
        'lib/data/repositories/home_repository.dart':
            ScreenTemplate.generateRepositoryImpl(_home, config),
        'lib/domain/usecases/get_home_data_usecase.dart':
            ScreenTemplate.generateUseCase(_home, config),
        'lib/features/home/models/home_model.dart':
            ScreenTemplate.generateModel(_home, config),
        'lib/features/home/viewmodels/home_viewmodel.dart':
            ScreenTemplate.generateViewModel(_home, config),
        'lib/features/home/views/home_view.dart':
            ScreenTemplate.generateView(_home, config),
        'lib/features/common/widgets/shared_widgets.dart':
            ScreenTemplate.generateSharedWidgetsPlaceholder(),
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
