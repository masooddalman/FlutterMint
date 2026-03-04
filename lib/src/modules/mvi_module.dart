import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/modules/module.dart';
import 'package:fluttermint/src/templates/mvi/bloc_template.dart';
import 'package:fluttermint/src/templates/mvi/mvi_screen_template.dart';

class MviModule extends Module {
  @override
  String get id => 'mvi';

  @override
  String get displayName => 'MVI Architecture (BLoC)';

  @override
  bool get isDefault => true;

  @override
  List<String> get dependsOn => [];

  @override
  Map<String, String> get dependencies => {
        'flutter_bloc': '^8.1.0',
        'equatable': '^2.0.0',
      };

  @override
  Map<String, String> get devDependencies => {
        'bloc_test': '^9.1.0',
      };

  static const _home = 'home';

  @override
  Map<String, String> generateFiles(ProjectConfig config) => {
        'lib/core/base/base_event.dart':
            BlocTemplate.generateBaseEvent(config),
        'lib/core/base/base_state.dart':
            BlocTemplate.generateBaseState(config),
        'lib/features/home/bloc/home_bloc.dart':
            MviScreenTemplate.generateBloc(_home, config),
        'lib/features/home/bloc/home_event.dart':
            MviScreenTemplate.generateEvent(_home, config),
        'lib/features/home/bloc/home_state.dart':
            MviScreenTemplate.generateState(_home, config),
        'lib/domain/repositories/home_repository.dart':
            MviScreenTemplate.generateRepository(_home, config),
        'lib/data/repositories/home_repository.dart':
            MviScreenTemplate.generateRepositoryImpl(_home, config),
        'lib/domain/usecases/get_home_data_usecase.dart':
            MviScreenTemplate.generateUseCase(_home, config),
        'lib/features/home/models/home_model.dart':
            MviScreenTemplate.generateModel(_home, config),
        'lib/features/home/views/home_view.dart':
            MviScreenTemplate.generateView(_home, config),
        'lib/features/common/widgets/shared_widgets.dart':
            MviScreenTemplate.generateSharedWidgetsPlaceholder(),
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
        'package:${config.appNameSnakeCase}/features/home/bloc/home_bloc.dart',
      ];

  @override
  List<String> locatorRegistrations(ProjectConfig config) => [
        'locator.registerLazySingleton<HomeRepository>(() => HomeRepositoryImpl());',
        'locator.registerLazySingleton(() => GetHomeDataUseCase(locator<HomeRepository>()));',
        'locator.registerFactory(() => HomeBloc(locator<GetHomeDataUseCase>()));',
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
