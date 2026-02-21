import 'package:flutterforge/src/config/project_config.dart';

class ViewModelTemplate {
  ViewModelTemplate._();

  static String generate(ProjectConfig config) {
    return '''import 'package:flutter/foundation.dart';

abstract class BaseViewModel extends ChangeNotifier {
  bool _isBusy = false;
  bool _isDisposed = false;
  String? _errorMessage;

  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  void setBusy(bool value) {
    if (_isDisposed) return;
    _isBusy = value;
    notifyListeners();
  }

  void setError(String? message) {
    if (_isDisposed) return;
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() => setError(null);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
''';
  }
}
