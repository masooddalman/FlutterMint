import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:flutterforge/src/cli/commands/add_command.dart';
import 'package:flutterforge/src/cli/commands/config_command.dart';
import 'package:flutterforge/src/cli/commands/create_command.dart';
import 'package:flutterforge/src/cli/commands/disable_http_command.dart';
import 'package:flutterforge/src/cli/commands/enable_http_command.dart';
import 'package:flutterforge/src/cli/commands/remove_command.dart';
import 'package:flutterforge/src/cli/commands/run_command.dart';
import 'package:flutterforge/src/cli/logo.dart';
import 'package:flutterforge/src/cli/commands/screen_command.dart';
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
    addCommand(ScreenCommand());
    addCommand(EnableHttpCommand());
    addCommand(DisableHttpCommand());
    addCommand(RunCommand());
    argParser.addFlag(
      'version',
      abbr: 'v',
      negatable: false,
      help: 'Print the tool version.',
    );
  }

  @override
  void printUsage() => printBanner(commands);

  @override
  Future<void> run(Iterable<String> args) async {
    try {
      final results = parse(args);
      if (results['version'] == true) {
        print('FlutterForge v${Constants.version}');
        return;
      }
      // No command specified — show the styled banner
      if (results.command == null && results.rest.isEmpty) {
        printBanner(commands);
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
