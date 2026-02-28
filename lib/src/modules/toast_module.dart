import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/modules/module.dart';
import 'package:fluttermint/src/templates/services/toast_template.dart';

class ToastModule extends Module {
  @override
  String get id => 'toast';

  @override
  String get displayName => 'Toast Notifications';

  @override
  bool get isDefault => false;

  @override
  List<String> get dependsOn => [];

  @override
  Map<String, String> get dependencies => {};

  @override
  Map<String, String> get devDependencies => {};

  @override
  Map<String, String> generateFiles(ProjectConfig config) => {
        'lib/core/services/toast_service.dart':
            ToastTemplate.generate(config),
      };

  @override
  List<String> mainImports(ProjectConfig config) => [];

  @override
  List<String> mainSetupLines(ProjectConfig config) => [];

  @override
  List<String> locatorImports(ProjectConfig config) => [];

  @override
  List<String> locatorRegistrations(ProjectConfig config) => [];

  @override
  List<String> providerDeclarations(ProjectConfig config) => [];

  @override
  List<String> appImports(ProjectConfig config) => [
        'package:${config.appNameSnakeCase}/core/services/toast_service.dart',
      ];
}
