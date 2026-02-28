import 'package:fluttermint/src/config/cicd_config.dart';
import 'package:fluttermint/src/config/project_config.dart';

class GithubActionsTemplate {
  GithubActionsTemplate._();

  static String generate(ProjectConfig config, {CicdConfig? cicdConfig}) {
    final cicd = cicdConfig ?? CicdConfig.defaults;
    final hasTests = config.hasModule('testing');
    final buf = StringBuffer();

    // Header
    buf.writeln('name: CI');
    buf.writeln('');

    // Triggers
    final branchList = cicd.branches.join(', ');
    buf.writeln('on:');
    buf.writeln('  push:');
    buf.writeln('    branches: [$branchList]');
    buf.writeln('  pull_request:');
    buf.writeln('    branches: [$branchList]');

    // Concurrency
    if (cicd.concurrency) {
      buf.writeln('');
      buf.writeln('concurrency:');
      buf.writeln('  group: \${{ github.workflow }}-\${{ github.ref }}');
      buf.writeln('  cancel-in-progress: true');
    }

    buf.writeln('');
    buf.writeln('jobs:');
    buf.writeln('  build:');
    buf.writeln('    runs-on: ubuntu-latest');
    buf.writeln('');
    buf.writeln('    steps:');
    buf.writeln('      - uses: actions/checkout@v4');
    buf.writeln('');
    buf.writeln('      - uses: subosito/flutter-action@v2');
    buf.writeln('        with:');
    buf.writeln('          channel: stable');

    // Caching
    if (cicd.caching) {
      buf.writeln('          cache: true');
    }

    // Install dependencies
    buf.writeln('');
    buf.writeln('      - name: Install dependencies');
    buf.writeln('        run: flutter pub get');

    // Format check
    if (cicd.formatCheck) {
      buf.writeln('');
      buf.writeln('      - name: Check formatting');
      buf.writeln('        run: dart format --set-exit-if-changed .');
    }

    // Analyze
    buf.writeln('');
    buf.writeln('      - name: Analyze code');
    buf.writeln('        run: flutter analyze');

    // Tests
    if (hasTests && cicd.coverage) {
      buf.writeln('');
      buf.writeln('      - name: Run tests with coverage');
      buf.writeln('        run: flutter test --coverage');
      buf.writeln('');
      buf.writeln('      - name: Upload coverage to Codecov');
      buf.writeln('        uses: codecov/codecov-action@v4');
      buf.writeln('        with:');
      buf.writeln('          files: coverage/lcov.info');
      buf.writeln('          fail_ci_if_error: false');
    } else {
      buf.writeln('');
      buf.writeln('      - name: Run tests');
      buf.writeln('        run: flutter test');
    }

    // Build platforms + deployment
    if (cicd.isGlobalBuild) {
      for (final platform in cicd.allPlatforms) {
        if (cicd.hasIosDeploy && platform == 'ios') continue;
        _writeBuildStep(buf, platform);
        if (cicd.hasDeployment) {
          _writeDeploySteps(buf, platform, cicd);
        }
      }
    } else {
      for (final entry in cicd.branchBuilds.entries) {
        final branch = entry.key;
        for (final platform in entry.value) {
          if (cicd.hasIosDeploy && platform == 'ios') continue;
          _writeBuildStep(buf, platform, branch: branch);
          if (cicd.hasDeployment) {
            _writeDeploySteps(buf, platform, cicd, branch: branch);
          }
        }
      }
    }

    // iOS TestFlight deploy job (separate macOS runner)
    if (cicd.hasIosDeploy) {
      _writeIosDeployJob(buf, cicd);
    }

    buf.writeln('');
    return buf.toString();
  }

  static void _writeBuildStep(StringBuffer buf, String platform, {String? branch}) {
    final condition = branch != null
        ? "\n        if: github.ref == 'refs/heads/$branch'"
        : '';

    buf.writeln('');
    switch (platform) {
      case 'apk':
        buf.writeln('      - name: Build APK${branch != null ? ' ($branch)' : ''}$condition');
        buf.writeln('        run: flutter build apk --debug');
      case 'aab':
        buf.writeln('      - name: Build App Bundle${branch != null ? ' ($branch)' : ''}$condition');
        buf.writeln('        run: flutter build appbundle --release');
      case 'web':
        buf.writeln('      - name: Build Web${branch != null ? ' ($branch)' : ''}$condition');
        buf.writeln('        run: flutter build web');
      case 'ios':
        buf.writeln('      - name: Build iOS${branch != null ? ' ($branch)' : ''}$condition');
        buf.writeln('        run: flutter build ios --release --no-codesign');
    }
  }

  static void _writeDeploySteps(
    StringBuffer buf,
    String platform,
    CicdConfig cicd, {
    String? branch,
  }) {
    if (platform != 'apk' && platform != 'aab') return;

    // Build if: condition — always push-only, plus optional branch
    final conditions = <String>["github.event_name == 'push'"];
    if (branch != null) {
      conditions.add("github.ref == 'refs/heads/$branch'");
    }
    final ifCondition = conditions.join(' && ');

    // Firebase App Distribution
    if (cicd.firebaseDistribution) {
      if (platform == 'apk') {
        _writeFirebaseStep(
          buf,
          label: 'Deploy APK to Firebase${branch != null ? ' ($branch)' : ''}',
          file: 'build/app/outputs/flutter-apk/app-debug.apk',
          ifCondition: ifCondition,
          groups: cicd.firebaseGroups,
          releaseNotesFile: cicd.autoPublish ? 'whatsnew/whatsnew-en-US' : null,
        );
      } else if (platform == 'aab') {
        _writeFirebaseStep(
          buf,
          label: 'Deploy AAB to Firebase${branch != null ? ' ($branch)' : ''}',
          file: 'build/app/outputs/bundle/release/app-release.aab',
          ifCondition: ifCondition,
          groups: cicd.firebaseGroups,
          releaseNotesFile: cicd.autoPublish ? 'whatsnew/whatsnew-en-US' : null,
        );
      }
    }

    // Google Play (AAB only)
    if (cicd.googlePlayUpload && platform == 'aab') {
      buf.writeln('');
      buf.writeln('      - name: Upload to Google Play${branch != null ? ' ($branch)' : ''}');
      buf.writeln('        if: $ifCondition');
      buf.writeln('        uses: r0adkll/upload-google-play@v1');
      buf.writeln('        with:');
      buf.writeln('          serviceAccountJsonPlainText: \${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON }}');
      buf.writeln('          packageName: ${cicd.packageName}');
      buf.writeln('          releaseFiles: build/app/outputs/bundle/release/app-release.aab');
      buf.writeln('          track: ${cicd.googlePlayTrack}');
      if (cicd.autoPublish) {
        buf.writeln('          status: completed');
        buf.writeln('          whatsNewDirectory: whatsnew/');
      }
    }
  }

  static void _writeFirebaseStep(
    StringBuffer buf, {
    required String label,
    required String file,
    required String ifCondition,
    required String groups,
    String? releaseNotesFile,
  }) {
    buf.writeln('');
    buf.writeln('      - name: $label');
    buf.writeln('        if: $ifCondition');
    buf.writeln('        uses: wzieba/Firebase-Distribution-Github-Action@v1');
    buf.writeln('        with:');
    buf.writeln('          appId: \${{ secrets.FIREBASE_APP_ID }}');
    buf.writeln('          serviceCredentialsFileContent: \${{ secrets.FIREBASE_SERVICE_ACCOUNT }}');
    buf.writeln('          groups: $groups');
    buf.writeln('          file: $file');
    if (releaseNotesFile != null) {
      buf.writeln('          releaseNotesFile: $releaseNotesFile');
    }
  }

  static void _writeIosDeployJob(StringBuffer buf, CicdConfig cicd) {
    buf.writeln('');
    buf.writeln('  ios-deploy:');
    buf.writeln('    runs-on: macos-latest');
    buf.writeln('    needs: [build]');
    buf.writeln("    if: github.event_name == 'push'");
    buf.writeln('');
    buf.writeln('    steps:');
    buf.writeln('      - uses: actions/checkout@v4');
    buf.writeln('');
    buf.writeln('      - uses: subosito/flutter-action@v2');
    buf.writeln('        with:');
    buf.writeln('          channel: stable');
    if (cicd.caching) {
      buf.writeln('          cache: true');
    }
    buf.writeln('');
    buf.writeln('      - name: Install dependencies');
    buf.writeln('        run: flutter pub get');
    buf.writeln('');
    buf.writeln('      - name: Import code signing certificate');
    buf.writeln('        uses: apple-actions/import-codesign-certs@v3');
    buf.writeln('        with:');
    buf.writeln('          p12-file-base64: \${{ secrets.IOS_P12_BASE64 }}');
    buf.writeln('          p12-password: \${{ secrets.IOS_P12_PASSWORD }}');
    buf.writeln('');
    buf.writeln('      - name: Download provisioning profiles');
    buf.writeln('        uses: apple-actions/download-provisioning-profiles@v3');
    buf.writeln('        with:');
    buf.writeln('          bundle-id: ${cicd.bundleId}');
    buf.writeln('          issuer-id: \${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}');
    buf.writeln('          api-key-id: \${{ secrets.APP_STORE_CONNECT_KEY_ID }}');
    buf.writeln('          api-private-key: \${{ secrets.APP_STORE_CONNECT_PRIVATE_KEY }}');
    buf.writeln('');
    buf.writeln('      - name: Build IPA');
    buf.writeln('        run: flutter build ipa --release');
    buf.writeln('');
    buf.writeln('      - name: Upload to TestFlight');
    buf.writeln('        uses: apple-actions/upload-testflight-build@v3');
    buf.writeln('        with:');
    buf.writeln('          app-path: build/ios/ipa/*.ipa');
    buf.writeln('          issuer-id: \${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}');
    buf.writeln('          api-key-id: \${{ secrets.APP_STORE_CONNECT_KEY_ID }}');
    buf.writeln('          api-private-key: \${{ secrets.APP_STORE_CONNECT_PRIVATE_KEY }}');
  }
}
