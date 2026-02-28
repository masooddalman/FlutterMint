import 'dart:io';

import 'package:fluttermint/src/cli/runner.dart';

Future<void> main(List<String> args) async {
  try {
    final runner = FlutterMintRunner();
    await runner.run(args);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}
