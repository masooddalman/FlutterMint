import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/modules/module.dart';
import 'package:fluttermint/src/templates/riverpod/riverpod_screen_template.dart';

class RiverpodModule extends Module {
  @override
  String get id => 'riverpod';

  @override
  String get displayName => 'MVVM + Riverpod';

  @override
  bool get isDefault => true;

  @override
  List<String> get dependsOn => [];

  @override
  Map<String, String> get dependencies => {
        'flutter_riverpod': '^2.6.1',
      };

  @override
  Map<String, String> get devDependencies => {};

  static const _home = 'home';

  @override
  Map<String, String> generateFiles(ProjectConfig config) => {
        'lib/features/home/notifiers/home_notifier.dart':
            RiverpodScreenTemplate.generateNotifier(_home, config),
        'lib/features/home/providers/home_providers.dart':
            RiverpodScreenTemplate.generateProviders(_home, config),
        'lib/features/home/views/home_view.dart':
            RiverpodScreenTemplate.generateView(_home, config),
        'lib/domain/repositories/home_repository.dart':
            RiverpodScreenTemplate.generateRepository(_home, config),
        'lib/data/repositories/home_repository.dart':
            RiverpodScreenTemplate.generateRepositoryImpl(_home, config),
        'lib/domain/usecases/get_home_data_usecase.dart':
            RiverpodScreenTemplate.generateUseCase(_home, config),
        'lib/features/home/models/home_model.dart':
            RiverpodScreenTemplate.generateModel(_home, config),
        'lib/features/common/widgets/shared_widgets.dart':
            RiverpodScreenTemplate.generateSharedWidgetsPlaceholder(),
      };

  @override
  List<String> mainImports(ProjectConfig config) => [
        'package:flutter_riverpod/flutter_riverpod.dart',
      ];

  @override
  List<String> mainSetupLines(ProjectConfig config) => [];

  @override
  List<String> locatorImports(ProjectConfig config) => [];

  @override
  List<String> locatorRegistrations(ProjectConfig config) => [];

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
