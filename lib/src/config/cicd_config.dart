import 'package:yaml/yaml.dart';

class CicdConfig {
  const CicdConfig({
    this.branches = const ['main'],
    this.formatCheck = true,
    this.caching = true,
    this.coverage = false,
    this.concurrency = true,
    this.platforms = const ['apk'],
  });

  final List<String> branches;
  final bool formatCheck;
  final bool caching;
  final bool coverage;
  final bool concurrency;
  final List<String> platforms;

  /// Default config — matches the old hardcoded behavior.
  static const CicdConfig defaults = CicdConfig(
    formatCheck: false,
    caching: false,
    coverage: false,
    concurrency: false,
    platforms: ['apk'],
  );

  static CicdConfig? fromYaml(YamlMap? yaml) {
    if (yaml == null) return null;

    final branchesList = yaml['branches'] as YamlList?;
    final platformsList = yaml['platforms'] as YamlList?;

    return CicdConfig(
      branches: branchesList?.cast<String>().toList() ?? const ['main'],
      formatCheck: yaml['format_check'] as bool? ?? true,
      caching: yaml['caching'] as bool? ?? true,
      coverage: yaml['coverage'] as bool? ?? false,
      concurrency: yaml['concurrency'] as bool? ?? true,
      platforms: platformsList?.cast<String>().toList() ?? const ['apk'],
    );
  }

  List<String> toYamlLines() {
    final lines = <String>[];
    lines.add('cicd:');
    lines.add('  branches:');
    for (final branch in branches) {
      lines.add('    - $branch');
    }
    lines.add('  format_check: $formatCheck');
    lines.add('  caching: $caching');
    lines.add('  coverage: $coverage');
    lines.add('  concurrency: $concurrency');
    lines.add('  platforms:');
    for (final platform in platforms) {
      lines.add('    - $platform');
    }
    return lines;
  }

  static const Map<String, String> platformLabels = {
    'apk': 'Android APK (debug)',
    'aab': 'Android App Bundle (release)',
    'web': 'Web',
    'ios': 'iOS',
  };
}
