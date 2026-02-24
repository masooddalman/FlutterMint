import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:flutterforge/src/config/forge_config.dart';
import 'package:flutterforge/src/generator/platform_configurator.dart';

class EnableHttpCommand extends Command<void> {
  EnableHttpCommand() {
    argParser.addFlag(
      'debug',
      abbr: 'd',
      negatable: false,
      help: 'Enable HTTP only for debug builds.',
    );
  }

  @override
  final String name = 'enable-http';

  @override
  final String description =
      'Enable HTTP (non-HTTPS) connections for Android and iOS.\n'
      'Usage: flutterforge enable-http [--debug]';

  @override
  Future<void> run() async {
    final projectPath = Directory.current.path;

    final forgeConfig = ForgeConfig.load(projectPath);
    if (forgeConfig == null) {
      stderr.writeln(
        'Error: No FlutterForge project found in the current directory.',
      );
      stderr.writeln(
        'Make sure you are inside a project created with "flutterforge create".',
      );
      return;
    }

    final debugOnly = argResults?['debug'] == true;

    print('');
    if (debugOnly) {
      print('Enabling HTTP connections (debug builds only)...');
    } else {
      print('Enabling HTTP connections (all builds)...');
    }
    print('');

    // Android
    print('  Android:');
    if (debugOnly) {
      await PlatformConfigurator.enableHttpAndroidDebug(projectPath);
    } else {
      await PlatformConfigurator.enableHttpAndroid(projectPath);
    }

    // iOS
    print('  iOS:');
    if (debugOnly) {
      print('    Skipped. iOS does not support per-build-type Info.plist.');
      print('    Configure NSAppTransportSecurity in ios/Runner/Info.plist manually.');
    } else {
      await PlatformConfigurator.enableHttpIos(projectPath);
    }

    print('');
    print('Done! HTTP connections are now enabled.');
    print('');
  }
}
