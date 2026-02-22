import 'package:flutterforge/src/config/project_config.dart';

class ToastTemplate {
  ToastTemplate._();

  static String generate(ProjectConfig config) {
    return '''import 'package:flutter/material.dart';

enum ToastType { success, error, warning, info }

class ToastService {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static void show(
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = messengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_iconForType(type), color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: _colorForType(type),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void success(String message) =>
      show(message, type: ToastType.success);

  static void error(String message) =>
      show(message, type: ToastType.error);

  static void warning(String message) =>
      show(message, type: ToastType.warning);

  static void info(String message) =>
      show(message, type: ToastType.info);

  static Color _colorForType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Colors.green.shade700;
      case ToastType.error:
        return Colors.red.shade700;
      case ToastType.warning:
        return Colors.orange.shade700;
      case ToastType.info:
        return Colors.blue.shade700;
    }
  }

  static IconData _iconForType(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.warning:
        return Icons.warning_amber_outlined;
      case ToastType.info:
        return Icons.info_outline;
    }
  }
}
''';
  }
}
