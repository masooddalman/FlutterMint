import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:flutterforge/src/config/constants.dart';

// ANSI color codes — degrade to empty strings when not supported.
final bool _ansi = stdout.supportsAnsiEscapes;

String get _cyan => _ansi ? '\x1B[96m' : '';
String get _blue => _ansi ? '\x1B[34m' : '';
String get _bold => _ansi ? '\x1B[1m' : '';
String get _dim => _ansi ? '\x1B[2m' : '';
String get _reset => _ansi ? '\x1B[0m' : '';

/// The "Flutter" half of the logo in ANSI Shadow font.
const _flutterArt = [
  r' ███████╗██╗     ██╗   ██╗████████╗████████╗███████╗██████╗ ',
  r' ██╔════╝██║     ██║   ██║╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗',
  r' █████╗  ██║     ██║   ██║   ██║      ██║   █████╗  ██████╔╝',
  r' ██╔══╝  ██║     ██║   ██║   ██║      ██║   ██╔══╝  ██╔══██╗',
  r' ██║     ███████╗╚██████╔╝   ██║      ██║   ███████╗██║  ██║',
  r' ╚═╝     ╚══════╝ ╚═════╝    ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝',
];

/// The "Forge" half of the logo in ANSI Shadow font.
const _forgeArt = [
  r' ███████╗ ██████╗ ██████╗  ██████╗ ███████╗',
  r' ██╔════╝██╔═══██╗██╔══██╗██╔════╝ ██╔════╝',
  r' █████╗  ██║   ██║██████╔╝██║  ███╗█████╗  ',
  r' ██╔══╝  ██║   ██║██╔══██╗██║   ██║██╔══╝  ',
  r' ██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗',
  r' ╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝',
];

/// Prints the colored FlutterForge logo, version,
/// and a styled list of available commands.
void printBanner(Map<String, Command<void>> commands) {
  // Logo — "Flutter" in bright cyan, "Forge" in blue
  print('');
  for (final line in _flutterArt) {
    print('$_cyan$line$_reset');
  }
  for (final line in _forgeArt) {
    print('$_blue$line$_reset');
  }

  // Version + description
  print('');
  print(' $_bold${Constants.toolName}$_reset  $_dim v${Constants.version}$_reset');
  print(' $_dim${Constants.description}$_reset');

  // Commands table
  print('');
  print(' $_bold Usage:$_reset  ${Constants.toolName} <command> [arguments]');
  print('');
  print(' $_bold Commands:$_reset');
  print('');

  // Compute padding for alignment
  final maxLen = commands.keys
      .fold<int>(0, (m, k) => k.length > m ? k.length : m);

  for (final entry in commands.entries) {
    final padded = entry.key.padRight(maxLen + 2);
    // First sentence of description (before newline)
    final desc = entry.value.description.split('\n').first;
    print('   $_cyan$padded$_reset $desc');
  }

  // Options
  print('');
  print(' $_bold Options:$_reset');
  print('');
  print('   $_cyan-h, --help$_reset     Print this usage information.');
  print('   $_cyan-v, --version$_reset  Print the tool version.');

  // Footer
  print('');
  print(' ${_dim}Run "${Constants.toolName} help <command>" for more information.$_reset');
  print('');
}
