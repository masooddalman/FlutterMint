import 'dart:convert';

import 'package:fluttermint/src/config/flavors_config.dart';

class EnvConfigTemplate {
  EnvConfigTemplate._();

  /// Generates `lib/core/config/env_config.dart` — a class that reads
  /// compile-time constants injected via `--dart-define-from-file`.
  static String generateEnvConfig({
    required FlavorsConfig flavorsConfig,
  }) {
    final envNames = flavorsConfig.environments.map((e) => e.name).toList();

    // Collect all unique custom keys across all environments
    final customKeys = <String>{};
    for (final env in flavorsConfig.environments) {
      customKeys.addAll(env.custom.keys);
    }

    // Generate bool getters for each environment
    final boolGetters = envNames.map((name) {
      return "  static bool get is${_toPascalCase(name)} => environment == '$name';";
    }).join('\n');

    // Generate static const for each custom key
    final customFields = customKeys.map((key) {
      final fieldName = _toCamelCase(key);
      return "  static const String $fieldName = String.fromEnvironment('$key');";
    }).join('\n');

    final customBlock = customFields.isNotEmpty ? '\n$customFields\n' : '';

    return '''/// Environment configuration using compile-time constants.
/// Values are injected via --dart-define-from-file.
///
/// Usage:
///   flutter run --dart-define-from-file=config/dev.json
class EnvConfig {
  const EnvConfig._();

  static const String environment =
      String.fromEnvironment('ENV', defaultValue: '${flavorsConfig.defaultEnvironment}');
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL');
  static const String appNameSuffix =
      String.fromEnvironment('APP_NAME_SUFFIX');
  static const String appIdSuffix =
      String.fromEnvironment('APP_ID_SUFFIX');
$customBlock
$boolGetters
}
''';
  }

  /// Generates a JSON config file for a specific environment, e.g.
  /// `config/dev.json`. Used with `--dart-define-from-file`.
  static String generateEnvironmentJson({
    required EnvironmentConfig env,
  }) {
    final map = <String, String>{
      'ENV': env.name,
      'API_BASE_URL': env.apiBaseUrl,
      'APP_NAME_SUFFIX': env.appNameSuffix,
      'APP_ID_SUFFIX': env.appIdSuffix,
    };

    // Add custom key-value pairs
    for (final entry in env.custom.entries) {
      map[entry.key] = entry.value;
    }

    const encoder = JsonEncoder.withIndent('  ');
    return '${encoder.convert(map)}\n';
  }

  static String _toCamelCase(String input) {
    final parts = input.split(RegExp(r'[-_\s]+'));
    if (parts.isEmpty) return input;
    final first = parts.first.toLowerCase();
    final rest = parts.skip(1).map(
      (s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1).toLowerCase(),
    );
    return '$first${rest.join()}';
  }

  static String _toPascalCase(String input) {
    return input
        .split(RegExp(r'[-_\s]+'))
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
        .join();
  }
}
