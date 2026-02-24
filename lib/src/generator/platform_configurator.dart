import 'dart:io';

import 'package:path/path.dart' as p;

/// Utility for modifying Android and iOS platform files.
class PlatformConfigurator {
  /// Adds `<uses-permission>` entries to the main AndroidManifest.xml.
  ///
  /// Idempotent: skips permissions that already exist.
  static Future<void> addAndroidPermissions(
    String projectPath,
    List<String> permissions,
  ) async {
    final manifestPath = p.join(
      projectPath,
      'android',
      'app',
      'src',
      'main',
      'AndroidManifest.xml',
    );

    final file = File(manifestPath);
    if (!await file.exists()) {
      stderr.writeln('Warning: AndroidManifest.xml not found. Skipping.');
      return;
    }

    var content = await file.readAsString();
    final linesToAdd = <String>[];

    for (final permission in permissions) {
      final line = '<uses-permission android:name="$permission" />';
      if (!content.contains(line)) {
        linesToAdd.add('    $line');
      }
    }

    if (linesToAdd.isEmpty) return;

    // Insert before the <application tag
    final appTag = RegExp(r'(\s*)<application');
    final match = appTag.firstMatch(content);
    if (match == null) {
      stderr.writeln('Warning: Could not find <application> in AndroidManifest.xml.');
      stderr.writeln('Add these permissions manually:');
      for (final line in linesToAdd) {
        stderr.writeln('  $line');
      }
      return;
    }

    final block = '${linesToAdd.join('\n')}\n';
    content = content.replaceFirst(appTag, '$block${match.group(0)}');
    await file.writeAsString(content);

    for (final permission in permissions) {
      if (linesToAdd.any((l) => l.contains(permission))) {
        print('    + $permission');
      }
    }
  }

  /// Enables cleartext HTTP traffic on Android for all build variants.
  ///
  /// Adds `android:usesCleartextTraffic="true"` to the `<application>` tag
  /// in the main AndroidManifest.xml.
  static Future<void> enableHttpAndroid(String projectPath) async {
    final manifestPath = p.join(
      projectPath,
      'android',
      'app',
      'src',
      'main',
      'AndroidManifest.xml',
    );
    await _addCleartextTraffic(manifestPath);
  }

  /// Enables cleartext HTTP traffic on Android for debug builds only.
  ///
  /// Adds `android:usesCleartextTraffic="true"` to the `<application>` tag
  /// in the debug AndroidManifest.xml.
  static Future<void> enableHttpAndroidDebug(String projectPath) async {
    final manifestPath = p.join(
      projectPath,
      'android',
      'app',
      'src',
      'debug',
      'AndroidManifest.xml',
    );
    await _addCleartextTraffic(manifestPath);
  }

  /// Enables HTTP connections on iOS by configuring App Transport Security.
  ///
  /// Adds `NSAppTransportSecurity` with `NSAllowsArbitraryLoads = true`
  /// to `ios/Runner/Info.plist`.
  static Future<void> enableHttpIos(String projectPath) async {
    final plistPath = p.join(
      projectPath,
      'ios',
      'Runner',
      'Info.plist',
    );

    final file = File(plistPath);
    if (!await file.exists()) {
      stderr.writeln('Warning: ios/Runner/Info.plist not found. Skipping iOS.');
      return;
    }

    var content = await file.readAsString();

    if (content.contains('NSAppTransportSecurity')) {
      print('    iOS: NSAppTransportSecurity already configured.');
      return;
    }

    // Insert before the closing </dict> that is a child of the root <plist>
    // The Info.plist structure is:
    //   <plist>
    //     <dict>
    //       ...entries...
    //     </dict>
    //   </plist>
    const atsBlock = '''
\t<key>NSAppTransportSecurity</key>
\t<dict>
\t\t<key>NSAllowsArbitraryLoads</key>
\t\t<true/>
\t</dict>''';

    // Find the last </dict> before </plist>
    final closingDict = content.lastIndexOf('</dict>');
    if (closingDict == -1) {
      stderr.writeln('Warning: Could not parse Info.plist. Add NSAppTransportSecurity manually.');
      return;
    }

    content = '${content.substring(0, closingDict)}$atsBlock\n${'</dict>'}${content.substring(closingDict + '</dict>'.length)}';
    await file.writeAsString(content);
    print('    + NSAppTransportSecurity (NSAllowsArbitraryLoads = true)');
  }

  /// Adds `android:usesCleartextTraffic="true"` to an AndroidManifest.xml.
  static Future<void> _addCleartextTraffic(String manifestPath) async {
    final file = File(manifestPath);
    if (!await file.exists()) {
      stderr.writeln('Warning: $manifestPath not found. Skipping.');
      return;
    }

    var content = await file.readAsString();

    if (content.contains('android:usesCleartextTraffic')) {
      print('    Android: usesCleartextTraffic already configured.');
      return;
    }

    // Add the attribute to the <application tag
    content = content.replaceFirst(
      '<application',
      '<application\n        android:usesCleartextTraffic="true"',
    );

    await file.writeAsString(content);
    print('    + android:usesCleartextTraffic="true"');
  }
}
