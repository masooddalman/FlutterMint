import 'package:fluttermint/src/config/project_config.dart';

class LocatorTemplate {
  LocatorTemplate._();

  static String generate({
    required ProjectConfig config,
    required List<String> imports,
    required List<String> registrations,
  }) {
    final importBlock = imports.isNotEmpty
        ? imports.map((i) => "import '$i';").join('\n')
        : '';

    final registrationBlock = registrations.isNotEmpty
        ? registrations.map((r) => '  $r').join('\n')
        : '';

    return '''import 'package:get_it/get_it.dart';
${importBlock.isNotEmpty ? '\n$importBlock\n' : ''}
final GetIt locator = GetIt.instance;

void setupLocator() {
${registrationBlock.isNotEmpty ? '$registrationBlock\n' : ''}}
''';
  }
}
