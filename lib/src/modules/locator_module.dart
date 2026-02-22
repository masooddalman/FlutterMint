import 'package:flutterforge/src/config/project_config.dart';
import 'package:flutterforge/src/modules/module.dart';

class LocatorModule extends Module {
  @override
  String get id => 'locator';

  @override
  String get displayName => 'Service Locator (GetIt)';

  @override
  bool get isDefault => false;

  @override
  List<String> get dependsOn => [];

  @override
  Map<String, String> get dependencies => {'get_it': '^8.0.0'};

  @override
  Map<String, String> get devDependencies => {};

  @override
  Map<String, String> generateFiles(ProjectConfig config) => {};

  @override
  List<String> mainImports(ProjectConfig config) => [
        'package:${config.appNameSnakeCase}/app/locator.dart',
      ];

  @override
  List<String> mainSetupLines(ProjectConfig config) => [
        'setupLocator();',
      ];

  @override
  List<String> locatorImports(ProjectConfig config) => [];

  @override
  List<String> locatorRegistrations(ProjectConfig config) => [];

  @override
  List<String> providerDeclarations(ProjectConfig config) => [];

  @override
  List<String> appImports(ProjectConfig config) => [];
}
