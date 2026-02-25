class PlatformInfo {
  const PlatformInfo({
    required this.id,
    required this.displayName,
    required this.buildTargets,
    this.isDefault = false,
  });

  final String id;
  final String displayName;

  /// Each entry is `(label, flutter build subcommand)`.
  final List<(String, String)> buildTargets;
  final bool isDefault;
}

class PlatformRegistry {
  PlatformRegistry._();

  static const android = PlatformInfo(
    id: 'android',
    displayName: 'Android',
    buildTargets: [('APK', 'apk'), ('App Bundle (AAB)', 'appbundle')],
    isDefault: true,
  );

  static const ios = PlatformInfo(
    id: 'ios',
    displayName: 'iOS',
    buildTargets: [('iOS (.app)', 'ios')],
    isDefault: true,
  );

  static const web = PlatformInfo(
    id: 'web',
    displayName: 'Web',
    buildTargets: [('Web', 'web')],
  );

  static const macos = PlatformInfo(
    id: 'macos',
    displayName: 'macOS',
    buildTargets: [('macOS', 'macos')],
  );

  static const windows = PlatformInfo(
    id: 'windows',
    displayName: 'Windows',
    buildTargets: [('Windows', 'windows')],
  );

  static const linux = PlatformInfo(
    id: 'linux',
    displayName: 'Linux',
    buildTargets: [('Linux', 'linux')],
  );

  static const List<PlatformInfo> allPlatforms = [
    android,
    ios,
    web,
    macos,
    windows,
    linux,
  ];

  static const List<String> defaultPlatformIds = ['android', 'ios'];

  static const List<PlatformInfo> optionalPlatforms = [
    web,
    macos,
    windows,
    linux,
  ];

  static PlatformInfo? byId(String id) {
    for (final p in allPlatforms) {
      if (p.id == id) return p;
    }
    return null;
  }
}
