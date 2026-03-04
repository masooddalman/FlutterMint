import 'package:fluttermint/src/config/project_config.dart';

class BlocTemplate {
  BlocTemplate._();

  static String generateBaseEvent(ProjectConfig config) {
    return '''/// Marker interface for all BLoC events.
abstract class BaseEvent {
  const BaseEvent();
}
''';
  }

  static String generateBaseState(ProjectConfig config) {
    return '''/// Shared status enum used across all BLoC states.
enum StateStatus { initial, loading, success, error }
''';
  }
}
