import 'package:flutterforge/src/config/project_config.dart';
import 'package:flutterforge/src/modules/module.dart';
import 'package:flutterforge/src/templates/testing/test_helpers_template.dart';

class TestingModule extends Module {
  @override
  String get id => 'testing';

  @override
  String get displayName => 'Testing Framework';

  @override
  bool get isDefault => false;

  @override
  List<String> get dependsOn => ['mvvm'];

  @override
  Map<String, String> get dependencies => {};

  @override
  Map<String, String> get devDependencies => {
        'mocktail': '^1.0.0',
      };

  @override
  Map<String, String> generateFiles(ProjectConfig config) => {
        'test/helpers/test_helpers.dart':
            TestHelpersTemplate.generateTestHelpers(config),
        'test/features/home/home_viewmodel_test.dart':
            TestHelpersTemplate.generateUnitTestExample(config),
        'test/features/home/home_view_test.dart':
            TestHelpersTemplate.generateWidgetTestExample(config),
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
  List<String> appImports(ProjectConfig config) => [];
}
