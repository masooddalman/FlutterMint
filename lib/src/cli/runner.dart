import 'package:args/command_runner.dart';

import 'package:flutterforge/src/cli/commands/create_command.dart';
import 'package:flutterforge/src/config/constants.dart';

class FlutterForgeRunner extends CommandRunner<void> {
  FlutterForgeRunner()
      : super(Constants.toolName, Constants.description) {
    addCommand(CreateCommand());
    argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Print the tool version.',
    );
  }

  @override
  Future<void> run(Iterable<String> args) async {
    try {
      final results = parse(args);
      if (results['version'] == true) {
        print('${Constants.toolName} version ${Constants.version}');
        return;
      }
      await super.run(args);
    } on UsageException catch (e) {
      print(e.message);
      print('');
      print(e.usage);
    }
  }
}
