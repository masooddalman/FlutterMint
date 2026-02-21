import 'dart:io';

import 'package:flutterforge/src/cli/runner.dart';

Future<void> main(List<String> args) async {
  try {
    final runner = FlutterForgeRunner();
    await runner.run(args);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
