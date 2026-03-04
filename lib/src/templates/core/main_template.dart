import 'package:fluttermint/src/config/design_pattern.dart';
import 'package:fluttermint/src/config/project_config.dart';

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

    final isRiverpod = config.designPattern == DesignPattern.riverpod;
    final appWidget = '${config.appNamePascalCase}App()';
    final runAppLine = isRiverpod
        ? '  runApp(const ProviderScope(child: $appWidget));'
        : '  runApp(const $appWidget);';

    return '''import 'package:flutter/material.dart';
import 'package:${config.appNameSnakeCase}/app/app.dart';
${importBlock.isNotEmpty ? '\n$importBlock\n' : ''}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
${setupBlock.isNotEmpty ? '\n$setupBlock\n' : ''}
$runAppLine
}
''';
  }
}
