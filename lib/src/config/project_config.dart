import 'package:flutterforge/src/config/cicd_config.dart';
import 'package:flutterforge/src/config/flavors_config.dart';

class ProjectConfig {
  const ProjectConfig({
    required this.appName,
    required this.selectedModules,
    this.org = 'com.example',
    this.cicdConfig,
    this.flavorsConfig,
    this.platforms = const ['android', 'ios'],
  });

  final String appName;
  final String org;
  final List<String> selectedModules;
  final CicdConfig? cicdConfig;
  final FlavorsConfig? flavorsConfig;
  final List<String> platforms;

  /// Full package identifier (e.g. com.mycompany.my_app).
  String get packageId => '$org.$appName';

  String get appNameSnakeCase => _toSnakeCase(appName);

  String get appNamePascalCase => toPascalCase(appName);

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

  static String toPascalCase(String input) {
    return input
        .replaceAll(RegExp(r'[-_\s]+'), ' ')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
        .join();
  }
}
