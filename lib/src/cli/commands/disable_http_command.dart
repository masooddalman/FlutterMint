import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:flutterforge/src/config/forge_config.dart';
import 'package:flutterforge/src/generator/platform_configurator.dart';

class DisableHttpCommand extends Command<void> {
  @override
  final String name = 'disable-http';

  @override
  final String description =
      'Disable HTTP (non-HTTPS) connections for Android and iOS.\n'
      'Usage: flutterforge disable-http';

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

    print('');
    print('Disabling HTTP connections...');
    print('');

    // Android
    print('  Android:');
    await PlatformConfigurator.disableHttpAndroid(projectPath);

    // iOS
    print('  iOS:');
    await PlatformConfigurator.disableHttpIos(projectPath);

    print('');
    print('Done! HTTP connections are now disabled (HTTPS only).');
    print('');
  }
}
