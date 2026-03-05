import 'package:fluttermint/src/config/design_pattern.dart';
import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/modules/module.dart';
import 'package:fluttermint/src/templates/services/preferences_template.dart';

class PreferencesModule extends Module {
  @override
  String get id => 'preferences';

  @override
  String get displayName => 'Local Preferences (SharedPreferences)';

  @override
  bool get isDefault => false;

  @override
  List<String> get dependsOn => [];

  @override
  Map<String, String> get dependencies => {'shared_preferences': '^2.3.0'};

  @override
  Map<String, String> get devDependencies => {};

  @override
  Map<String, String> generateFiles(ProjectConfig config) {
    final files = <String, String>{
      'lib/core/preferences/preferences_service.dart':
          PreferencesTemplate.generatePreferencesService(config),
    };

    if (config.designPattern == DesignPattern.riverpod) {
      files['lib/core/preferences/preferences_providers.dart'] =
          PreferencesTemplate.generatePreferencesProviders(config);
    }

    return files;
  }

  @override
  List<String> mainImports(ProjectConfig config) {
    final imports = <String>[
      'package:shared_preferences/shared_preferences.dart',
    ];

    if (config.designPattern == DesignPattern.riverpod) {
      imports.add(
        'package:${config.appNameSnakeCase}/core/preferences/preferences_providers.dart',
      );
    } else if (config.hasModule('locator')) {
      imports.add(
        'package:${config.appNameSnakeCase}/core/preferences/preferences_service.dart',
      );
    }

    return imports;
  }

  @override
  List<String> mainSetupLines(ProjectConfig config) {
    final lines = <String>[
      'final prefs = await SharedPreferences.getInstance();',
    ];

    if (config.designPattern != DesignPattern.riverpod &&
        config.hasModule('locator')) {
      lines.add(
        'locator.registerLazySingleton<PreferencesService>(() => PreferencesService(prefs));',
      );
    }

    return lines;
  }

  @override
  List<String> mainProviderOverrides(ProjectConfig config) {
    if (config.designPattern == DesignPattern.riverpod) {
      return ['sharedPreferencesProvider.overrideWithValue(prefs)'];
    }
    return [];
  }

  @override
  List<String> locatorImports(ProjectConfig config) => [];

  @override
  List<String> locatorRegistrations(ProjectConfig config) => [];

  @override
  List<String> providerDeclarations(ProjectConfig config) => [];

  @override
  List<String> appImports(ProjectConfig config) => [];
}
