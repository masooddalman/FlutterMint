import 'package:fluttermint/src/config/project_config.dart';

class ViewModelTemplate {
  ViewModelTemplate._();

  static String generate(ProjectConfig config) {
    return '''import 'package:flutter/foundation.dart';

enum ViewState { initial, loading, success, error }

abstract class BaseViewModel extends ChangeNotifier {
  bool _isDisposed = false;

  // --- Screen-level state (enum) ---

  ViewState _state = ViewState.initial;
  String? _errorMessage;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _state == ViewState.loading;
  bool get hasError => _state == ViewState.error;

  void setLoading() {
    _state = ViewState.loading;
    _errorMessage = null;
    _notify();
  }

  void setSuccess() {
    _state = ViewState.success;
    _errorMessage = null;
    _notify();
  }

  void setError(String message) {
    _state = ViewState.error;
    _errorMessage = message;
    _notify();
  }

  // --- Per-operation state (for parallel calls on one screen) ---

  final Map<String, ViewState> _keyStates = {};
  final Map<String, String> _keyErrors = {};

  ViewState stateOf(String key) => _keyStates[key] ?? ViewState.initial;
  String? errorFor(String key) => _keyErrors[key];
  bool busy(String key) => stateOf(key) == ViewState.loading;

  void setLoadingForKey(String key) =>
      _setStateForKey(key, ViewState.loading);

  void setSuccessForKey(String key) =>
      _setStateForKey(key, ViewState.success);

  void setErrorForKey(String key, String message) =>
      _setStateForKey(key, ViewState.error, error: message);

  void _setStateForKey(String key, ViewState state, {String? error}) {
    if (_isDisposed) return;
    _keyStates[key] = state;
    if (state == ViewState.error && error != null) {
      _keyErrors[key] = error;
    } else {
      _keyErrors.remove(key);
    }
    notifyListeners();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
''';
  }
}
