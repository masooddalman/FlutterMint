import 'dart:io';

class PromptUtils {
  PromptUtils._();

  static String askText(String prompt, {String? defaultValue}) {
    final suffix = defaultValue != null ? ' [$defaultValue]' : '';
    stdout.write('$prompt$suffix: ');
    final input = stdin.readLineSync()?.trim();
    if (input == null || input.isEmpty) {
      if (defaultValue != null) return defaultValue;
      print('  Input required. Please try again.');
      return askText(prompt, defaultValue: defaultValue);
    }
    return input;
  }

  static bool askYesNo(String prompt, {bool defaultValue = false}) {
    final suffix = defaultValue ? '[Y/n]' : '[y/N]';
    stdout.write('$prompt $suffix: ');
    final input = stdin.readLineSync()?.trim().toLowerCase();
    if (input == null || input.isEmpty) return defaultValue;
    return input == 'y' || input == 'yes';
  }

  static void printHeader(String text) {
    final line = '─' * (text.length + 4);
    print('');
    print('┌$line┐');
    print('│  $text  │');
    print('└$line┘');
    print('');
  }

  static void printStep(int current, int total, String label) {
    print('  [$current/$total] $label');
  }

  static void printSuccess(String message) {
    print('  ✓ $message');
  }
}
