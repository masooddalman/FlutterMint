import 'package:flutterforge/src/config/project_config.dart';

class GithubActionsTemplate {
  GithubActionsTemplate._();

  static String generate(ProjectConfig config) {
    final hasTests = config.hasModule('testing');
    final testStep = hasTests
        ? '''
      - name: Run tests
        run: flutter test --coverage
'''
        : '''
      - name: Run tests
        run: flutter test
''';

    return '''name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          channel: stable

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze code
        run: flutter analyze

$testStep
      - name: Build APK
        run: flutter build apk --debug
''';
  }
}
