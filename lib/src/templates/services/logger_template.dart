import 'package:flutterforge/src/config/project_config.dart';

class LoggerTemplate {
  LoggerTemplate._();

  static String generate(ProjectConfig config) {
    return """import 'dart:developer' as developer;

enum LogLevel { debug, info, warning, error }

class LoggerService {
  static LogLevel _minimumLevel = LogLevel.debug;

  static void setMinimumLevel(LogLevel level) {
    _minimumLevel = level;
  }

  static void debug(String message, {String? tag}) {
    _log(message, tag: tag, level: LogLevel.debug);
  }

  static void info(String message, {String? tag}) {
    _log(message, tag: tag, level: LogLevel.info);
  }

  static void warning(String message, {String? tag}) {
    _log(message, tag: tag, level: LogLevel.warning);
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      message,
      tag: tag,
      level: LogLevel.error,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void _log(
    String message, {
    String? tag,
    required LogLevel level,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minimumLevel.index) return;

    final prefix = '[\${level.name.toUpperCase()}]';
    final logTag = tag ?? '${config.appNamePascalCase}';

    developer.log(
      '\$prefix \$message',
      name: logTag,
      error: error,
      stackTrace: stackTrace,
      level: _levelToInt(level),
    );
  }

  static int _levelToInt(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}
""";
  }
}
