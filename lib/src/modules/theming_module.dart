import 'package:fluttermint/src/config/design_pattern.dart';
import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/modules/module.dart';
import 'package:fluttermint/src/templates/services/theme_template.dart';

class ThemingModule extends Module {
  @override
  String get id => 'theming';

  @override
  String get displayName => 'Theming (Light/Dark)';

  @override
  bool get isDefault => false;

  @override
  List<String> get dependsOn => [];

  @override
  Map<String, String> get dependencies => {
        'provider': '^6.1.0',
      };

  @override
  Map<String, String> resolvedDependencies(ProjectConfig config) {
    if (config.designPattern == DesignPattern.riverpod) return {};
    return dependencies;
  }

  @override
  Map<String, String> get devDependencies => {};

  @override
  Map<String, String> generateFiles(ProjectConfig config) {
    if (config.designPattern == DesignPattern.riverpod) {
      return {
        'lib/core/theme/app_theme.dart':
            ThemeTemplate.generateAppTheme(config),
        'lib/core/theme/theme_notifier.dart':
            ThemeTemplate.generateThemeNotifier(config),
      };
    }
    return {
      'lib/core/theme/app_theme.dart':
          ThemeTemplate.generateAppTheme(config),
      'lib/core/theme/theme_provider.dart':
          ThemeTemplate.generateThemeProvider(config),
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
  List<String> providerDeclarations(ProjectConfig config) {
    if (config.designPattern == DesignPattern.riverpod) return [];
    return [
      'ChangeNotifierProvider(create: (_) => ThemeProvider()),',
    ];
  }

  @override
  List<String> appImports(ProjectConfig config) {
    if (config.designPattern == DesignPattern.riverpod) {
      return [
        'package:${config.appNameSnakeCase}/core/theme/app_theme.dart',
        'package:${config.appNameSnakeCase}/core/theme/theme_notifier.dart',
      ];
    }
    return [
      'package:${config.appNameSnakeCase}/core/theme/app_theme.dart',
      'package:${config.appNameSnakeCase}/core/theme/theme_provider.dart',
    ];
  }
}
