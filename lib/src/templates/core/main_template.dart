import 'package:flutterforge/src/config/project_config.dart';

class MainTemplate {
  MainTemplate._();

  static String generate({
    required ProjectConfig config,
    required List<String> imports,
    required List<String> setupLines,
  }) {
    final importBlock = imports.isNotEmpty
        ? imports.map((i) => "import '$i';").join('\n')
        : '';

    final setupBlock = setupLines.isNotEmpty
        ? setupLines.map((l) => '  $l').join('\n')
        : '';

    return '''import 'package:flutter/material.dart';
import 'package:${config.appNameSnakeCase}/app/app.dart';
${importBlock.isNotEmpty ? '\n$importBlock\n' : ''}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
${setupBlock.isNotEmpty ? '\n$setupBlock\n' : ''}
  runApp(const ${config.appNamePascalCase}App());
}
''';
  }
}
