import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:flutterforge/src/cli/commands/add_command.dart';
import 'package:flutterforge/src/cli/commands/config_command.dart';
import 'package:flutterforge/src/cli/commands/create_command.dart';
import 'package:flutterforge/src/cli/commands/remove_command.dart';
import 'package:flutterforge/src/cli/commands/status_command.dart';
import 'package:flutterforge/src/config/constants.dart';

class FlutterForgeRunner extends CommandRunner<void> {
  FlutterForgeRunner()
      : super(Constants.toolName, Constants.description) {
    addCommand(CreateCommand());
    addCommand(AddCommand());
    addCommand(RemoveCommand());
    addCommand(ConfigCommand());
    addCommand(StatusCommand());
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
        print('FlutterForge v${Constants.version}');
        return;
      }
      await super.run(args);
    } on UsageException catch (e) {
      stderr.writeln(e.message);
      print('');
      print(e.usage);
    } on ProcessException catch (e) {
      stderr.writeln('Process error: ${e.message}');
      exit(1);
    } catch (e) {
      stderr.writeln('Error: $e');
      exit(1);
    }
  }
}
