import 'package:flutterforge/src/config/cicd_config.dart';

class ProjectConfig {
  const ProjectConfig({
    required this.appName,
    required this.selectedModules,
    this.cicdConfig,
  });

  final String appName;
  final List<String> selectedModules;
  final CicdConfig? cicdConfig;

  String get appNameSnakeCase => _toSnakeCase(appName);

  String get appNamePascalCase => _toPascalCase(appName);

  bool hasModule(String moduleId) => selectedModules.contains(moduleId);

  static String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceAll(RegExp(r'[-\s]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_'), '')
        .toLowerCase();
  }

  static String _toPascalCase(String input) {
    return input
        .replaceAll(RegExp(r'[-_\s]+'), ' ')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
        .join();
  }
}
