import 'package:yaml/yaml.dart';

class CicdConfig {
  const CicdConfig({
    this.branches = const ['main'],
    this.formatCheck = true,
    this.caching = true,
    this.coverage = false,
    this.concurrency = true,
    this.branchBuilds = const {},
    this.firebaseDistribution = false,
    this.googlePlayUpload = false,
    this.googlePlayTrack = 'internal',
    this.packageName = '',
    this.firebaseGroups = 'testers',
    this.autoPublish = false,
  });

  final List<String> branches;
  final bool formatCheck;
  final bool caching;
  final bool coverage;
  final bool concurrency;

  /// Per-branch build platforms.
  /// Empty map = global default (['apk'] for all branches).
  /// e.g. {'main': ['aab'], 'develop': ['apk']}
  final Map<String, List<String>> branchBuilds;

  // Deployment
  final bool firebaseDistribution;
  final bool googlePlayUpload;
  final String googlePlayTrack;
  final String packageName;
  final String firebaseGroups;
  final bool autoPublish;

  /// Get platforms for a specific branch.
  List<String> platformsForBranch(String branch) {
    if (branchBuilds.containsKey(branch)) return branchBuilds[branch]!;
    return const ['apk'];
  }

  /// True if all branches share the same platforms (or no per-branch config).
  bool get isGlobalBuild {
    if (branchBuilds.isEmpty) return true;
    if (branchBuilds.length != branches.length) return false;
    final first = branchBuilds.values.first;
    return branchBuilds.values.every(
      (v) => v.length == first.length && v.toSet().containsAll(first),
    );
  }

  /// True if any deployment is configured.
  bool get hasDeployment => firebaseDistribution || googlePlayUpload;

  /// All unique platforms across all branches (for global mode or fallback).
  List<String> get allPlatforms {
    if (branchBuilds.isEmpty) return const ['apk'];
    final all = <String>{};
    for (final platforms in branchBuilds.values) {
      all.addAll(platforms);
    }
    return all.toList();
  }

  /// Default config — matches the old hardcoded behavior.
  static const CicdConfig defaults = CicdConfig(
    formatCheck: false,
    caching: false,
    coverage: false,
    concurrency: false,
    firebaseDistribution: false,
    googlePlayUpload: false,
    autoPublish: false,
  );

  static CicdConfig? fromYaml(YamlMap? yaml) {
    if (yaml == null) return null;

    final branchesList = yaml['branches'] as YamlList?;

    // Parse builds — supports both old flat format and new per-branch format
    final branchBuilds = <String, List<String>>{};
    final buildsYaml = yaml['builds'];
    if (buildsYaml is YamlMap) {
      // Per-branch format: builds: { main: [aab], develop: [apk] }
      for (final entry in buildsYaml.entries) {
        final branch = entry.key as String;
        final platforms = (entry.value as YamlList).cast<String>().toList();
        branchBuilds[branch] = platforms;
      }
    } else {
      // Old flat format: platforms: [apk, web]
      final platformsList = yaml['platforms'] as YamlList?;
      if (platformsList != null) {
        final platforms = platformsList.cast<String>().toList();
        final branches =
            branchesList?.cast<String>().toList() ?? const ['main'];
        for (final branch in branches) {
          branchBuilds[branch] = platforms;
        }
      }
    }

    // Parse deployment config
    final deployYaml = yaml['deployment'];
    var firebaseDistribution = false;
    var googlePlayUpload = false;
    var googlePlayTrack = 'internal';
    var packageName = '';
    var firebaseGroups = 'testers';
    var autoPublish = false;

    if (deployYaml is YamlMap) {
      firebaseDistribution =
          deployYaml['firebase_distribution'] as bool? ?? false;
      googlePlayUpload = deployYaml['google_play_upload'] as bool? ?? false;
      googlePlayTrack =
          deployYaml['google_play_track'] as String? ?? 'internal';
      packageName = deployYaml['package_name'] as String? ?? '';
      firebaseGroups = deployYaml['firebase_groups'] as String? ?? 'testers';
      autoPublish = deployYaml['auto_publish'] as bool? ?? false;
    }

    return CicdConfig(
      branches: branchesList?.cast<String>().toList() ?? const ['main'],
      formatCheck: yaml['format_check'] as bool? ?? true,
      caching: yaml['caching'] as bool? ?? true,
      coverage: yaml['coverage'] as bool? ?? false,
      concurrency: yaml['concurrency'] as bool? ?? true,
      branchBuilds: branchBuilds,
      firebaseDistribution: firebaseDistribution,
      googlePlayUpload: googlePlayUpload,
      googlePlayTrack: googlePlayTrack,
      packageName: packageName,
      firebaseGroups: firebaseGroups,
      autoPublish: autoPublish,
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
    if (branchBuilds.isNotEmpty) {
      lines.add('  builds:');
      for (final entry in branchBuilds.entries) {
        lines.add('    ${entry.key}:');
        for (final platform in entry.value) {
          lines.add('      - $platform');
        }
      }
    }
    if (hasDeployment) {
      lines.add('  deployment:');
      lines.add('    firebase_distribution: $firebaseDistribution');
      lines.add('    firebase_groups: $firebaseGroups');
      lines.add('    google_play_upload: $googlePlayUpload');
      if (googlePlayUpload) {
        lines.add('    google_play_track: $googlePlayTrack');
        lines.add('    package_name: $packageName');
      }
      lines.add('    auto_publish: $autoPublish');
    }
    return lines;
  }

  static const Map<String, String> platformLabels = {
    'apk': 'Android APK (debug)',
    'aab': 'Android App Bundle (release)',
    'web': 'Web',
    'ios': 'iOS',
  };

  static const Map<String, String> trackLabels = {
    'internal': 'Internal testing',
    'alpha': 'Closed testing (alpha)',
    'beta': 'Open testing (beta)',
    'production': 'Production',
  };
}
