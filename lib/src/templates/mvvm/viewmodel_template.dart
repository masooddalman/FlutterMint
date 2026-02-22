import 'package:flutterforge/src/config/project_config.dart';

class ViewModelTemplate {
  ViewModelTemplate._();

  static String generate(ProjectConfig config) {
    return '''import 'package:flutter/foundation.dart';

abstract class BaseViewModel extends ChangeNotifier {
  bool _isDisposed = false;
  final Set<String> _busyKeys = {};
  final Map<String, String> _errors = {};

  static const String _globalKey = '_global';

  // --- Busy state ---

  /// True if any operation is in progress.
  bool get isBusy => _busyKeys.isNotEmpty;

  /// True if the operation identified by [key] is in progress.
  bool busy(String key) => _busyKeys.contains(key);

  /// Set the global busy state (for simple single-operation screens).
  void setBusy(bool value) => setBusyForKey(_globalKey, value);

  /// Set the busy state for a specific operation.
  void setBusyForKey(String key, bool value) {
    if (_isDisposed) return;
    if (value) {
      _busyKeys.add(key);
    } else {
      _busyKeys.remove(key);
    }
    notifyListeners();
  }

  // --- Error state ---

  /// The global error message (from [setError]).
  String? get errorMessage => _errors[_globalKey];

  /// The error message for a specific operation.
  String? errorFor(String key) => _errors[key];

  /// True if any error exists.
  bool get hasError => _errors.isNotEmpty;

  /// Set the global error message.
  void setError(String? message) => setErrorForKey(_globalKey, message);

  /// Set the error message for a specific operation.
  void setErrorForKey(String key, String? message) {
    if (_isDisposed) return;
    if (message == null) {
      _errors.remove(key);
    } else {
      _errors[key] = message;
    }
    notifyListeners();
  }

  /// Clear the global error.
  void clearError() => setError(null);

  /// Clear the error for a specific operation.
  void clearErrorForKey(String key) => setErrorForKey(key, null);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
''';
  }
}
