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
  List<String> get dependsOn => ['mvvm'];

  @override
  Map<String, String> get dependencies => {};

  @override
  Map<String, String> get devDependencies => {};

  @override
  Map<String, String> generateFiles(ProjectConfig config) => {
        'lib/core/theme/app_theme.dart':
            ThemeTemplate.generateAppTheme(config),
        'lib/core/theme/theme_provider.dart':
            ThemeTemplate.generateThemeProvider(config),
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
  List<String> providerDeclarations(ProjectConfig config) => [
        'ChangeNotifierProvider(create: (_) => ThemeProvider()),',
      ];

  @override
  List<String> appImports(ProjectConfig config) => [
        'package:${config.appNameSnakeCase}/core/theme/app_theme.dart',
        'package:${config.appNameSnakeCase}/core/theme/theme_provider.dart',
      ];
}
