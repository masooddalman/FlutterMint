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

  /// Removes `android:usesCleartextTraffic="true"` from the main AndroidManifest.xml.
  static Future<void> disableHttpAndroid(String projectPath) async {
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

    if (!content.contains('android:usesCleartextTraffic')) {
      print('    Android: usesCleartextTraffic not found. Already disabled.');
      return;
    }

    // Remove the attribute and its preceding newline/whitespace
    content = content.replaceFirst(
      RegExp(r'\n\s*android:usesCleartextTraffic="true"'),
      '',
    );

    await file.writeAsString(content);
    print('    - android:usesCleartextTraffic removed');
  }

  /// Removes `NSAppTransportSecurity` block from `ios/Runner/Info.plist`.
  static Future<void> disableHttpIos(String projectPath) async {
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

    if (!content.contains('NSAppTransportSecurity')) {
      print('    iOS: NSAppTransportSecurity not found. Already disabled.');
      return;
    }

    // Remove the NSAppTransportSecurity block (key + dict)
    content = content.replaceFirst(
      RegExp(r'\s*<key>NSAppTransportSecurity</key>\s*<dict>\s*<key>NSAllowsArbitraryLoads</key>\s*<true/>\s*</dict>'),
      '',
    );

    await file.writeAsString(content);
    print('    - NSAppTransportSecurity removed');
  }

  // ---------------------------------------------------------------------------
  // Flavors: native platform configuration
  // ---------------------------------------------------------------------------

  /// Marker comment used to identify the dart-defines decoding block in
  /// build.gradle so it can be found (and removed) later.
  static const _gradleMarker = '// -- FlutterMint flavors --';

  /// Configures Android native files for flavor support.
  ///
  /// 1. Injects a dart-defines decoding block into `build.gradle`
  ///    that reads `APP_ID_SUFFIX` and `APP_NAME_SUFFIX` at build time.
  /// 2. Changes `android:label` in `AndroidManifest.xml` to
  ///    `@string/app_name` so the launcher name comes from resValue.
  static Future<void> configureFlavorsAndroid(
    String projectPath,
    String appName,
  ) async {
    await _injectGradleFlavors(projectPath, appName);
    await _setManifestLabelResource(projectPath);
  }

  /// Reverts the Android flavor configuration added by
  /// [configureFlavorsAndroid].
  static Future<void> revertFlavorsAndroid(
    String projectPath,
    String appName,
  ) async {
    await _removeGradleFlavors(projectPath);
    await _restoreManifestLabel(projectPath, appName);
  }

  /// Configures iOS Info.plist for flavor support.
  ///
  /// Sets `CFBundleDisplayName` to `\$(APP_DISPLAY_NAME)` so that an Xcode
  /// build-phase script or xcconfig variable can override it per environment.
  static Future<void> configureFlavorsIos(
    String projectPath,
    String appName,
  ) async {
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

    if (content.contains('DART_DEFINE_APP_NAME_SUFFIX')) {
      print('    iOS: Flavor display name already configured.');
      return;
    }

    // Add CFBundleDisplayName that appends the suffix
    // The DART_DEFINES are available in Generated.xcconfig but are base64
    // encoded. The simplest reliable approach is to add a Run Script phase.
    // For now we add a user-defined build setting placeholder and print a
    // hint for manual Xcode configuration.
    //
    // We insert a CFBundleDisplayName key right before the closing </dict>.
    final closingDict = content.lastIndexOf('</dict>');
    if (closingDict == -1) {
      stderr.writeln(
        'Warning: Could not parse Info.plist for flavor config.',
      );
      return;
    }

    const displayNameBlock = '''
\t<key>CFBundleDisplayName</key>
\t<string>\$(PRODUCT_NAME)\$(DART_DEFINE_APP_NAME_SUFFIX)</string>
''';

    content =
        '${content.substring(0, closingDict)}$displayNameBlock${content.substring(closingDict)}';
    await file.writeAsString(content);
    print('    + CFBundleDisplayName with flavor suffix placeholder');

    // Generate the decode script
    await _generateIosDecodeScript(projectPath, appName);
  }

  /// Reverts the iOS flavor configuration.
  static Future<void> revertFlavorsIos(String projectPath) async {
    final plistPath = p.join(
      projectPath,
      'ios',
      'Runner',
      'Info.plist',
    );

    final file = File(plistPath);
    if (!await file.exists()) return;

    var content = await file.readAsString();

    // Remove the CFBundleDisplayName block we added
    content = content.replaceFirst(
      RegExp(
        r'\s*<key>CFBundleDisplayName</key>\s*<string>\$\(PRODUCT_NAME\)\$\(DART_DEFINE_APP_NAME_SUFFIX\)</string>',
      ),
      '',
    );

    await file.writeAsString(content);

    // Remove decode script
    final scriptFile = File(
      p.join(projectPath, 'ios', 'Scripts', 'decode_dart_defines.sh'),
    );
    if (await scriptFile.exists()) {
      await scriptFile.delete();
      final scriptsDir = scriptFile.parent;
      if (await scriptsDir.exists() &&
          (await scriptsDir.list().toList()).isEmpty) {
        await scriptsDir.delete();
      }
    }
  }

  // ---- Android Gradle helpers ----

  /// Returns the path and whether it is Kotlin DSL (.kts).
  static (File, bool)? _findGradleFile(String projectPath) {
    final ktsFile = File(
      p.join(projectPath, 'android', 'app', 'build.gradle.kts'),
    );
    if (ktsFile.existsSync()) return (ktsFile, true);

    final groovyFile = File(
      p.join(projectPath, 'android', 'app', 'build.gradle'),
    );
    if (groovyFile.existsSync()) return (groovyFile, false);

    return null;
  }

  static Future<void> _injectGradleFlavors(
    String projectPath,
    String appName,
  ) async {
    final result = _findGradleFile(projectPath);
    if (result == null) {
      stderr.writeln(
        'Warning: android/app/build.gradle(.kts) not found. Skipping.',
      );
      return;
    }

    final (file, isKts) = result;
    var content = await file.readAsString();

    if (content.contains(_gradleMarker)) {
      print('    Android: Flavor build.gradle block already configured.');
      return;
    }

    // Build the PascalCase app name for the default resValue
    final pascalName = appName
        .split(RegExp(r'[-_\s]+'))
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
        .join();

    if (isKts) {
      content = _injectKts(content, pascalName);
    } else {
      content = _injectGroovy(content, pascalName);
    }

    await file.writeAsString(content);
    final fileName = isKts ? 'build.gradle.kts' : 'build.gradle';
    print('    + $fileName: dart-defines decoding + applicationIdSuffix + resValue');
  }

  static String _injectGroovy(String content, String pascalName) {
    final gradleBlock = '''

$_gradleMarker
// Decode --dart-define / --dart-define-from-file values so they are
// available to native Android configuration (applicationIdSuffix, resValue).
def dartDefines = [:]
if (project.hasProperty('dart-defines')) {
    project.property('dart-defines').split(',').each {
        try {
            def decoded = new String(it.decodeBase64(), 'UTF-8')
            def parts = decoded.split('=', 2)
            if (parts.length == 2) {
                dartDefines[parts[0]] = parts[1]
            }
        } catch (ignored) {}
    }
}
$_gradleMarker
''';

    final androidBlock = RegExp(r'^android\s*\{', multiLine: true);
    final match = androidBlock.firstMatch(content);
    if (match == null) return content;

    content =
        '${content.substring(0, match.start)}$gradleBlock${content.substring(match.start)}';

    final defaultConfigRe = RegExp(r'defaultConfig\s*\{');
    final dcMatch = defaultConfigRe.firstMatch(content);
    if (dcMatch != null) {
      final insertPos = dcMatch.end;
      final flavorLines = '''

        // FlutterMint: apply flavor suffixes from dart-defines
        def idSuffix = dartDefines['APP_ID_SUFFIX'] ?: ''
        if (idSuffix) {
            applicationIdSuffix idSuffix
        }
        resValue "string", "app_name", "$pascalName\${dartDefines['APP_NAME_SUFFIX'] ?: ''}"
''';
      content =
          '${content.substring(0, insertPos)}$flavorLines${content.substring(insertPos)}';
    }

    return content;
  }

  static String _injectKts(String content, String pascalName) {
    // Add import for Base64 at the top of the file if not present.
    // In Gradle Kotlin DSL, `java` is a DSL accessor, so `java.util.Base64`
    // does not resolve to the JDK class. An explicit import is required.
    if (!content.contains('import java.util.Base64')) {
      // Insert after the plugins {} block, or at the very top
      final pluginsClose = RegExp(r'^}\s*\n', multiLine: true);
      final pluginsMatch = pluginsClose.firstMatch(content);
      if (pluginsMatch != null) {
        content =
            '${content.substring(0, pluginsMatch.end)}\nimport java.util.Base64\n${content.substring(pluginsMatch.end)}';
      } else {
        content = 'import java.util.Base64\n\n$content';
      }
    }

    final gradleBlock = '''

$_gradleMarker
// Decode --dart-define / --dart-define-from-file values so they are
// available to native Android configuration (applicationIdSuffix, resValue).
val dartDefines = mutableMapOf<String, String>()
if (project.hasProperty("dart-defines")) {
    project.property("dart-defines").toString().split(",").forEach { entry ->
        try {
            val decoded = String(Base64.getDecoder().decode(entry), Charsets.UTF_8)
            val parts = decoded.split("=", limit = 2)
            if (parts.size == 2) {
                dartDefines[parts[0]] = parts[1]
            }
        } catch (_: Exception) {}
    }
}
$_gradleMarker
''';

    final androidBlock = RegExp(r'^android\s*\{', multiLine: true);
    final match = androidBlock.firstMatch(content);
    if (match == null) return content;

    content =
        '${content.substring(0, match.start)}$gradleBlock${content.substring(match.start)}';

    final defaultConfigRe = RegExp(r'defaultConfig\s*\{');
    final dcMatch = defaultConfigRe.firstMatch(content);
    if (dcMatch != null) {
      final insertPos = dcMatch.end;
      final flavorLines = '''

        // FlutterMint: apply flavor suffixes from dart-defines
        val idSuffix = dartDefines["APP_ID_SUFFIX"] ?: ""
        if (idSuffix.isNotEmpty()) {
            applicationIdSuffix = idSuffix
        }
        resValue("string", "app_name", "$pascalName\${dartDefines["APP_NAME_SUFFIX"] ?: ""}")
''';
      content =
          '${content.substring(0, insertPos)}$flavorLines${content.substring(insertPos)}';
    }

    return content;
  }

  static Future<void> _removeGradleFlavors(String projectPath) async {
    final result = _findGradleFile(projectPath);
    if (result == null) return;

    final (file, _) = result;
    var content = await file.readAsString();

    // Remove the dart-defines decoding block between markers
    content = content.replaceFirst(
      RegExp(
        r'\n' +
            RegExp.escape(_gradleMarker) +
            r'[\s\S]*?' +
            RegExp.escape(_gradleMarker) +
            r'\n',
      ),
      '\n',
    );

    // Remove the Base64 import added for Kotlin DSL
    content = content.replaceFirst(
      RegExp(r'\nimport java\.util\.Base64\n'),
      '\n',
    );

    // Remove the defaultConfig flavor lines (both Groovy and Kotlin patterns)
    content = content.replaceFirst(
      RegExp(
        r"\n\s*// FlutterMint: apply flavor suffixes from dart-defines\n"
        r"[\s\S]*?"
        r"(?:resValue[^\n]*\n)",
      ),
      '',
    );

    await file.writeAsString(content);
    print('    - build.gradle: removed flavor configuration');
  }

  // ---- Android Manifest helpers ----

  static Future<void> _setManifestLabelResource(String projectPath) async {
    final manifestPath = p.join(
      projectPath,
      'android',
      'app',
      'src',
      'main',
      'AndroidManifest.xml',
    );

    final file = File(manifestPath);
    if (!await file.exists()) return;

    var content = await file.readAsString();

    if (content.contains('android:label="@string/app_name"')) {
      print('    Android: Manifest label already uses @string/app_name.');
      return;
    }

    // Replace the existing android:label="..." with @string/app_name
    content = content.replaceFirst(
      RegExp(r'android:label="[^"]*"'),
      'android:label="@string/app_name"',
    );

    await file.writeAsString(content);
    print('    + AndroidManifest.xml: label → @string/app_name');
  }

  static Future<void> _restoreManifestLabel(
    String projectPath,
    String appName,
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
    if (!await file.exists()) return;

    var content = await file.readAsString();

    content = content.replaceFirst(
      'android:label="@string/app_name"',
      'android:label="$appName"',
    );

    await file.writeAsString(content);
    print('    - AndroidManifest.xml: label restored to "$appName"');
  }

  // ---- iOS helpers ----

  static Future<void> _generateIosDecodeScript(
    String projectPath,
    String appName,
  ) async {
    final scriptDir = Directory(p.join(projectPath, 'ios', 'Scripts'));
    if (!await scriptDir.exists()) {
      await scriptDir.create(recursive: true);
    }

    final scriptPath = p.join(scriptDir.path, 'decode_dart_defines.sh');
    const script = r'''#!/bin/bash
# Decode DART_DEFINES and export individual variables for Xcode build settings.
# Add this as a "Run Script" build phase BEFORE "Compile Sources".

if [ -z "$DART_DEFINES" ]; then
  exit 0
fi

IFS=',' read -ra ENTRIES <<< "$DART_DEFINES"
for entry in "${ENTRIES[@]}"; do
  decoded=$(echo "$entry" | base64 --decode 2>/dev/null || true)
  key="${decoded%%=*}"
  value="${decoded#*=}"
  if [ "$key" = "APP_NAME_SUFFIX" ]; then
    echo "DART_DEFINE_APP_NAME_SUFFIX=$value" >> "${SCRIPT_OUTPUT_FILE_0}"
  fi
done
''';

    await File(scriptPath).writeAsString(script);
    print('    + ios/Scripts/decode_dart_defines.sh');
    print('');
    print('    Note: To use flavor suffixes on iOS, add a "Run Script"');
    print('    build phase in Xcode before "Compile Sources":');
    print('      Script: \${SRCROOT}/Scripts/decode_dart_defines.sh');
    print('      Output files: \$(DERIVED_FILE_DIR)/dart_defines.xcconfig');
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
