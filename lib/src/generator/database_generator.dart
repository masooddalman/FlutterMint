import 'dart:io';

import 'package:path/path.dart' as p;

class DatabaseGenerator {
  static const _tableMarker = '// Add table creation here';
  static const _methodMarker = '// Add more tables here';

  /// Supported Dart types and their SQLite column types.
  static const _typeMap = {
    'String': 'TEXT',
    'int': 'INTEGER',
    'double': 'REAL',
    'bool': 'INTEGER',
    'DateTime': 'TEXT',
  };

  /// Returns the list of supported type names.
  static List<String> get supportedTypes => _typeMap.keys.toList();

  /// Generates a model class and injects table creation + CRUD into database_service.dart.
  Future<bool> generate(
    String projectPath,
    String tableName,
    List<ColumnDef> columns,
  ) async {
    final serviceFile = File(p.join(
      projectPath,
      'lib',
      'core',
      'database',
      'database_service.dart',
    ));
    if (!await serviceFile.exists()) {
      stderr.writeln('Error: database_service.dart not found.');
      stderr.writeln(
        'Make sure the database module is installed '
        '("fluttermint add database").',
      );
      return false;
    }

    var content = await serviceFile.readAsString();
    content = content.replaceAll('\r\n', '\n');

    if (!content.contains(_tableMarker)) {
      stderr.writeln('Error: Table marker not found in database_service.dart.');
      stderr.writeln('Add "$_tableMarker" inside the _onCreate method.');
      return false;
    }

    if (!content.contains(_methodMarker)) {
      stderr.writeln('Error: Method marker not found in database_service.dart.');
      stderr.writeln('Add "$_methodMarker" inside the DatabaseService class.');
      return false;
    }

    // Check if table already exists
    final className = _toPascalCase(tableName);
    if (content.contains("'$tableName'") ||
        content.contains('// --- $className CRUD ---')) {
      stderr.writeln('Error: Table "$tableName" already exists.');
      return false;
    }

    // 1. Generate model file
    await _generateModel(projectPath, tableName, columns);

    // 2. Inject CREATE TABLE into _onCreate
    final columnDefs = columns
        .map((c) => '${c.name} ${_typeMap[c.type]}')
        .join(', ');
    final createSql =
        "    await db.execute('CREATE TABLE $tableName(id INTEGER PRIMARY KEY AUTOINCREMENT, $columnDefs)');\n"
        '    $_tableMarker';
    content = content.replaceFirst(_tableMarker, createSql);

    // 3. Add import for model
    final modelImport =
        "import '${_toSnakeCase(className)}.dart';";
    if (!content.contains(modelImport)) {
      // Add relative import — models sit next to the service in the same dir
      // We need to use the models/ subfolder import
      final importLine =
          "import 'models/${_toSnakeCase(className)}.dart';";
      final lastImportIndex = content.lastIndexOf(RegExp(r'^import .*;\n', multiLine: true));
      if (lastImportIndex >= 0) {
        final endOfImport = content.indexOf('\n', lastImportIndex) + 1;
        content = '${content.substring(0, endOfImport)}$importLine\n${content.substring(endOfImport)}';
      }
    }

    // 4. Inject CRUD methods
    final crud = _generateCrud(tableName, className, columns);
    content = content.replaceFirst(_methodMarker, '$crud\n  $_methodMarker');

    await serviceFile.writeAsString(content);
    return true;
  }

  Future<void> _generateModel(
    String projectPath,
    String tableName,
    List<ColumnDef> columns,
  ) async {
    final className = _toPascalCase(tableName);
    final fileName = _toSnakeCase(className);

    final fields = StringBuffer();
    final constructorParams = StringBuffer();
    final toMapEntries = StringBuffer();
    final fromMapEntries = StringBuffer();

    // id field
    fields.writeln('  final int? id;');
    constructorParams.writeln('    this.id,');

    for (final col in columns) {
      fields.writeln('  final ${col.type} ${col.name};');
      constructorParams.writeln('    required this.${col.name},');

      if (col.type == 'bool') {
        toMapEntries.writeln("      '${col.name}': ${col.name} ? 1 : 0,");
        fromMapEntries.writeln(
            "      ${col.name}: map['${col.name}'] == 1,");
      } else if (col.type == 'DateTime') {
        toMapEntries.writeln("      '${col.name}': ${col.name}.toIso8601String(),");
        fromMapEntries.writeln(
            "      ${col.name}: DateTime.parse(map['${col.name}'] as String),");
      } else {
        toMapEntries.writeln("      '${col.name}': ${col.name},");
        fromMapEntries.writeln(
            "      ${col.name}: map['${col.name}'] as ${col.type},");
      }
    }

    final model = '''class $className {
  $className({
$constructorParams  });

${fields.toString().trimRight()}

  Map<String, dynamic> toMap() {
    return {
$toMapEntries    };
  }

  factory $className.fromMap(Map<String, dynamic> map) {
    return $className(
      id: map['id'] as int?,
$fromMapEntries    );
  }
}
''';

    final dir = Directory(
        p.join(projectPath, 'lib', 'core', 'database', 'models'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File(p.join(dir.path, '$fileName.dart'));
    await file.writeAsString(model);
  }

  String _generateCrud(
    String tableName,
    String className,
    List<ColumnDef> columns,
  ) {
    return '''// --- $className CRUD ---

  Future<int> insert$className($className item) async {
    final db = await database;
    return db.insert('$tableName', item.toMap());
  }

  Future<List<$className>> getAll$className() async {
    final db = await database;
    final maps = await db.query('$tableName');
    return maps.map((m) => $className.fromMap(m)).toList();
  }

  Future<$className?> get${className}ById(int id) async {
    final db = await database;
    final maps = await db.query(
      '$tableName',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return $className.fromMap(maps.first);
  }

  Future<int> update$className($className item) async {
    final db = await database;
    return db.update(
      '$tableName',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete$className(int id) async {
    final db = await database;
    return db.delete(
      '$tableName',
      where: 'id = ?',
      whereArgs: [id],
    );
  }''';
  }

  /// Removes a table's model file, CREATE TABLE SQL, import, and CRUD methods.
  Future<bool> remove(
    String projectPath,
    String tableName,
  ) async {
    final className = _toPascalCase(tableName);
    final fileName = _toSnakeCase(className);

    final serviceFile = File(p.join(
      projectPath,
      'lib',
      'core',
      'database',
      'database_service.dart',
    ));
    if (!await serviceFile.exists()) {
      stderr.writeln('Error: database_service.dart not found.');
      return false;
    }

    var content = await serviceFile.readAsString();
    content = content.replaceAll('\r\n', '\n');

    // Check table exists
    if (!content.contains('// --- $className CRUD ---')) {
      stderr.writeln('Error: Table "$tableName" not found in database_service.dart.');
      return false;
    }

    // 1. Remove CREATE TABLE line
    content = content.replaceAll(
      RegExp("    await db\\.execute\\('CREATE TABLE $tableName\\([^)]*\\)'\\);\n"),
      '',
    );

    // 2. Remove model import
    content = content.replaceAll(
      "import 'models/$fileName.dart';\n",
      '',
    );

    // 3. Remove CRUD block (from marker to next marker or method marker)
    final crudStart = content.indexOf('// --- $className CRUD ---');
    if (crudStart >= 0) {
      // Find the end: next CRUD marker or the method marker
      var crudEnd = content.indexOf('\n\n  // ---', crudStart + 1);
      if (crudEnd < 0) {
        crudEnd = content.indexOf('\n\n  $_methodMarker', crudStart);
      }
      if (crudEnd >= 0) {
        content = '${content.substring(0, crudStart)}${content.substring(crudEnd + 2)}';
      }
    }

    // Clean up extra blank lines
    content = content.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    await serviceFile.writeAsString(content);

    // 4. Delete model file
    final modelFile = File(p.join(
      projectPath, 'lib', 'core', 'database', 'models', '$fileName.dart',
    ));
    if (await modelFile.exists()) {
      await modelFile.delete();
      print('    Deleted lib/core/database/models/$fileName.dart');
    }

    // Clean up empty models directory
    final modelsDir = Directory(
        p.join(projectPath, 'lib', 'core', 'database', 'models'));
    if (await modelsDir.exists()) {
      final entries = await modelsDir.list().toList();
      if (entries.isEmpty) {
        await modelsDir.delete();
      }
    }

    return true;
  }

  static String _toPascalCase(String input) {
    // Convert snake_case or plural table name to PascalCase singular
    // e.g. "users" -> "User", "order_items" -> "OrderItem"
    var name = input;
    if (name.endsWith('ies')) {
      name = '${name.substring(0, name.length - 3)}y';
    } else if (name.endsWith('ses') || name.endsWith('xes') || name.endsWith('zes')) {
      name = name.substring(0, name.length - 2);
    } else if (name.endsWith('s') && !name.endsWith('ss')) {
      name = name.substring(0, name.length - 1);
    }
    return name
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join();
  }

  static String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'[A-Z]'),
          (match) => '_${match.group(0)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }
}

class ColumnDef {
  ColumnDef(this.name, this.type);

  final String name;
  final String type;
}
