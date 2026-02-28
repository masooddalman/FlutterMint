import 'package:fluttermint/src/config/flavors_config.dart';
import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/modules/module.dart';
import 'package:fluttermint/src/templates/flavors/env_config_template.dart';

class FlavorsModule extends Module {
  @override
  String get id => 'flavors';

  @override
  String get displayName => 'Flavors / Environments';

  @override
  bool get isDefault => false;

  @override
  List<String> get dependsOn => [];

  @override
  Map<String, String> get dependencies => {};

  @override
  Map<String, String> get devDependencies => {};

  @override
  Map<String, String> generateFiles(ProjectConfig config) {
    final flavorsConfig = config.flavorsConfig ?? FlavorsConfig.defaults;

    final files = <String, String>{};

    // EnvConfig class with String.fromEnvironment() compile-time constants
    files['lib/core/config/env_config.dart'] =
        EnvConfigTemplate.generateEnvConfig(
      flavorsConfig: flavorsConfig,
    );

    // Per-environment JSON config files for --dart-define-from-file
    for (final env in flavorsConfig.environments) {
      files['config/${env.name}.json'] =
          EnvConfigTemplate.generateEnvironmentJson(env: env);
    }

    return files;
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
