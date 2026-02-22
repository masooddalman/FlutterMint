import 'package:flutterforge/src/config/project_config.dart';
import 'package:flutterforge/src/modules/module.dart';
import 'package:flutterforge/src/templates/localization/l10n_template.dart';

class LocalizationModule extends Module {
  @override
  String get id => 'localization';

  @override
  String get displayName => 'Localization (intl)';

  @override
  bool get isDefault => false;

  @override
  List<String> get dependsOn => [];

  @override
  Map<String, String> get dependencies => {
        'intl': '^0.19.0',
      };

  @override
  Map<String, String> get sdkDependencies => {
        'flutter_localizations': 'flutter',
      };

  @override
  Map<String, String> get devDependencies => {};

  @override
  Map<String, String> generateFiles(ProjectConfig config) => {
        'lib/core/localization/arb/app_en.arb':
            L10nTemplate.generateArbEn(config),
        'lib/core/localization/arb/app_ar.arb':
            L10nTemplate.generateArbAr(config),
        'l10n.yaml': L10nTemplate.generateL10nYaml(config),
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
        'package:${config.appNameSnakeCase}/core/localization/generated/app_localizations.dart',
      ];
}
