import 'package:yaml/yaml.dart';

class EnvironmentConfig {
  const EnvironmentConfig({
    required this.name,
    required this.apiBaseUrl,
    this.appNameSuffix = '',
    this.appIdSuffix = '',
    this.custom = const {},
  });

  final String name;
  final String apiBaseUrl;
  final String appNameSuffix;
  final String appIdSuffix;
  final Map<String, String> custom;
}

class FlavorsConfig {
  const FlavorsConfig({
    required this.environments,
    this.defaultEnvironment = 'production',
  });

  final List<EnvironmentConfig> environments;
  final String defaultEnvironment;

  static const FlavorsConfig defaults = FlavorsConfig(
    environments: [
      EnvironmentConfig(
        name: 'dev',
        apiBaseUrl: 'https://dev-api.example.com',
        appNameSuffix: ' Dev',
        appIdSuffix: '.dev',
      ),
      EnvironmentConfig(
        name: 'staging',
        apiBaseUrl: 'https://staging-api.example.com',
        appNameSuffix: ' Staging',
        appIdSuffix: '.staging',
      ),
      EnvironmentConfig(
        name: 'production',
        apiBaseUrl: 'https://api.example.com',
      ),
    ],
    defaultEnvironment: 'production',
  );

  static FlavorsConfig? fromYaml(YamlMap? yaml) {
    if (yaml == null) return null;

    final defaultEnv = yaml['default'] as String? ?? 'production';
    final envList = yaml['environments'] as YamlList?;
    if (envList == null) return null;

    final environments = <EnvironmentConfig>[];
    for (final entry in envList) {
      if (entry is! YamlMap) continue;
      final name = entry['name'] as String?;
      if (name == null) continue;

      final custom = <String, String>{};
      final customYaml = entry['custom'] as YamlMap?;
      if (customYaml != null) {
        for (final kv in customYaml.entries) {
          custom[kv.key as String] = kv.value.toString();
        }
      }

      environments.add(EnvironmentConfig(
        name: name,
        apiBaseUrl: entry['api_base_url'] as String? ?? '',
        appNameSuffix: entry['app_name_suffix'] as String? ?? '',
        appIdSuffix: entry['app_id_suffix'] as String? ?? '',
        custom: custom,
      ));
    }

    if (environments.isEmpty) return null;

    return FlavorsConfig(
      environments: environments,
      defaultEnvironment: defaultEnv,
    );
  }

  List<String> toYamlLines() {
    final lines = <String>[];
    lines.add('flavors:');
    lines.add('  default: $defaultEnvironment');
    lines.add('  environments:');
    for (final env in environments) {
      lines.add('    - name: ${env.name}');
      lines.add('      api_base_url: ${env.apiBaseUrl}');
      if (env.appNameSuffix.isNotEmpty) {
        lines.add('      app_name_suffix: "${env.appNameSuffix}"');
      }
      if (env.appIdSuffix.isNotEmpty) {
        lines.add('      app_id_suffix: ${env.appIdSuffix}');
      }
      if (env.custom.isNotEmpty) {
        lines.add('      custom:');
        for (final entry in env.custom.entries) {
          lines.add('        ${entry.key}: ${entry.value}');
        }
      }
    }
    return lines;
  }
}
