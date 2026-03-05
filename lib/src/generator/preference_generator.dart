import 'dart:io';

import 'package:path/path.dart' as p;

class PreferenceGenerator {
  static const _marker = '// Add more preferences here';

  /// Supported types and their SharedPreferences method suffixes.
  static const _typeMap = {
    'String': 'String',
    'int': 'Int',
    'double': 'Double',
    'bool': 'Bool',
    'List<String>': 'StringList',
  };

  /// Returns the list of supported type names.
  static List<String> get supportedTypes => _typeMap.keys.toList();

  /// Generates a typed accessor method and injects it into preferences_service.dart.
  ///
  /// For `name: 'userEmail'`, `type: 'String'`, generates:
  /// ```dart
  /// String? userEmail([String? value]) {
  ///   if (value != null) {
  ///     _prefs.setString('user_email', value);
  ///     return value;
  ///   }
  ///   return _prefs.getString('user_email');
  /// }
  /// ```
  Future<bool> generate(
    String projectPath,
    String name,
    String type,
  ) async {
    final suffix = _typeMap[type];
    if (suffix == null) {
      stderr.writeln('Error: Unsupported type "$type".');
      stderr.writeln(
        'Supported types: ${_typeMap.keys.join(', ')}',
      );
      return false;
    }

    final filePath = p.join(
      projectPath,
      'lib',
      'core',
      'preferences',
      'preferences_service.dart',
    );
    final file = File(filePath);
    if (!await file.exists()) {
      stderr.writeln('Error: preferences_service.dart not found.');
      stderr.writeln(
        'Make sure the preferences module is installed '
        '("fluttermint add preferences").',
      );
      return false;
    }

    var content = await file.readAsString();

    // Check marker exists
    if (!content.contains(_marker)) {
      stderr.writeln('Error: Marker comment not found in preferences_service.dart.');
      stderr.writeln(
        'Add "$_marker" inside the PreferencesService class.',
      );
      return false;
    }

    // Check if already exists
    if (content.contains('$type? $name(')) {
      stderr.writeln('Error: Preference "$name" already exists.');
      return false;
    }

    // Build the storage key from camelCase to snake_case
    final key = _toSnakeCase(name);

    // Determine the nullable return type
    final returnType = '$type?';

    // Generate the accessor method
    final method = '''  $returnType $name([$type? value]) {
    if (value != null) {
      _prefs.set$suffix('$key', value);
      return value;
    }
    return _prefs.get$suffix('$key');
  }

  $_marker''';

    content = content.replaceFirst(_marker, method);
    await file.writeAsString(content);

    return true;
  }

  static String _toSnakeCase(String input) {
    return input.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    );
  }
}
