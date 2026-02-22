import 'package:flutterforge/src/config/cicd_config.dart';
import 'package:flutterforge/src/config/project_config.dart';

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

    // Build platforms
    for (final platform in cicd.platforms) {
      buf.writeln('');
      switch (platform) {
        case 'apk':
          buf.writeln('      - name: Build APK');
          buf.writeln('        run: flutter build apk --debug');
        case 'aab':
          buf.writeln('      - name: Build App Bundle');
          buf.writeln('        run: flutter build appbundle --release');
        case 'web':
          buf.writeln('      - name: Build Web');
          buf.writeln('        run: flutter build web');
        case 'ios':
          buf.writeln('      - name: Build iOS');
          buf.writeln('        run: flutter build ios --release --no-codesign');
      }
    }

    buf.writeln('');
    return buf.toString();
  }
}
