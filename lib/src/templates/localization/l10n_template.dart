import 'package:fluttermint/src/config/project_config.dart';

class L10nTemplate {
  L10nTemplate._();

  static String generateL10nYaml(ProjectConfig config) {
    return '''arb-dir: lib/core/localization/arb
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/core/localization/generated
synthetic-package: false
''';
  }

  static String generateArbEn(ProjectConfig config) {
    return '''{
  "@@locale": "en",
  "appTitle": "${config.appNamePascalCase}",
  "@appTitle": {
    "description": "The title of the application"
  },
  "homeTitle": "Home",
  "@homeTitle": {
    "description": "Title for the home screen"
  },
  "welcomeMessage": "Welcome to ${config.appNamePascalCase}!",
  "@welcomeMessage": {
    "description": "Welcome message shown on the home screen"
  }
}
''';
  }

  static String generateArbAr(ProjectConfig config) {
    return '''{
  "@@locale": "ar",
  "appTitle": "${config.appNamePascalCase}",
  "homeTitle": "الرئيسية",
  "welcomeMessage": "مرحباً بك في ${config.appNamePascalCase}!"
}
''';
  }
}
