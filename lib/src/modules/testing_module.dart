import 'package:fluttermint/src/config/design_pattern.dart';
import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/modules/module.dart';
import 'package:fluttermint/src/templates/testing/test_helpers_template.dart';

class TestingModule extends Module {
  @override
  String get id => 'testing';

  @override
  String get displayName => 'Testing Framework';

  @override
  bool get isDefault => false;

  @override
  List<String> get dependsOn => [];

  @override
  Map<String, String> get dependencies => {};

  @override
  Map<String, String> get devDependencies => {
        'mocktail': '^1.0.0',
      };

  @override
  Map<String, String> generateFiles(ProjectConfig config) {
    if (config.designPattern == DesignPattern.riverpod) {
      return {
        'test/helpers/test_helpers.dart':
            TestHelpersTemplate.generateTestHelpersRiverpod(config),
        'test/features/home/home_notifier_test.dart':
            TestHelpersTemplate.generateNotifierTestExample(config),
        'test/features/home/home_view_test.dart':
            TestHelpersTemplate.generateWidgetTestExampleRiverpod(config),
      };
    }
    if (config.designPattern == DesignPattern.mvi) {
      return {
        'test/helpers/test_helpers.dart':
            TestHelpersTemplate.generateTestHelpersMvi(config),
        'test/features/home/home_bloc_test.dart':
            TestHelpersTemplate.generateBlocTestExample(config),
        'test/features/home/home_view_test.dart':
            TestHelpersTemplate.generateWidgetTestExampleMvi(config),
      };
    }
    return {
      'test/helpers/test_helpers.dart':
          TestHelpersTemplate.generateTestHelpers(config),
      'test/features/home/home_viewmodel_test.dart':
          TestHelpersTemplate.generateUnitTestExample(config),
      'test/features/home/home_view_test.dart':
          TestHelpersTemplate.generateWidgetTestExample(config),
    };
  }

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
