import 'package:flutterforge/src/config/project_config.dart';
import 'package:flutterforge/src/modules/module.dart';
import 'package:flutterforge/src/templates/services/router_template.dart';

class RoutingModule extends Module {
  @override
  String get id => 'routing';

  @override
  String get displayName => 'Routing (GoRouter)';

  @override
  bool get isDefault => false;

  @override
  List<String> get dependsOn => [];

  @override
  Map<String, String> get dependencies => {'go_router': '^14.0.0'};

  @override
  Map<String, String> get devDependencies => {};

  @override
  Map<String, String> generateFiles(ProjectConfig config) => {
        'lib/core/routing/app_router.dart': RouterTemplate.generate(config),
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
        'package:${config.appNameSnakeCase}/core/routing/app_router.dart',
      ];
}
