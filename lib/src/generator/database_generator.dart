import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:fluttermint/src/config/design_pattern.dart';
import 'package:fluttermint/src/config/forge_config.dart';

class DatabaseGenerator {
  static const _tableMarker = '// Add table creation here';

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

  /// Generates a model class, a DAO file, injects CREATE TABLE, and registers DAO in DI.
  Future<bool> generate(
    String projectPath,
    String tableName,
    List<ColumnDef> columns,
    ForgeConfig config,
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

    // Check if table already exists
    if (content.contains('CREATE TABLE $tableName(')) {
      stderr.writeln('Error: Table "$tableName" already exists.');
      return false;
    }

    // 1. Generate model file
    await _generateModel(projectPath, tableName, columns);

    // 2. Generate DAO file
    await _generateDao(projectPath, tableName, columns, config);

    // 3. Inject CREATE TABLE into _onCreate
    final columnDefs = columns
        .map((c) => '${c.name} ${_typeMap[c.type]}')
        .join(', ');
    final createSql =
        "    await db.execute('CREATE TABLE $tableName(id INTEGER PRIMARY KEY AUTOINCREMENT, $columnDefs)');\n"
        '    $_tableMarker';
    content = content.replaceFirst(_tableMarker, createSql);

    await serviceFile.writeAsString(content);

    // 4. Register DAO in locator (for locator-based projects)
    if (config.designPattern != DesignPattern.riverpod &&
        config.modules.contains('locator')) {
      await _registerInLocator(projectPath, tableName, config);
    }

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

  Future<void> _generateDao(
    String projectPath,
    String tableName,
    List<ColumnDef> columns,
    ForgeConfig config,
  ) async {
    final className = _toPascalCase(tableName);
    final modelFileName = _toSnakeCase(className);
    final daoFileName = '${_toSnakeCase(className)}_dao';

    final isRiverpod = config.designPattern == DesignPattern.riverpod;
    final appName = _toSnakeCase(config.appName);

    final imports = StringBuffer();
    imports.writeln("import '../database_service.dart';");
    imports.writeln("import '../models/$modelFileName.dart';");
    if (isRiverpod) {
      imports.writeln();
      imports.writeln("import 'package:flutter_riverpod/flutter_riverpod.dart';");
      imports.writeln("import 'package:$appName/core/database/database_providers.dart';");
    }

    final providerSuffix = isRiverpod
        ? '''

final ${_toCamelCase(className)}DaoProvider = Provider<${className}Dao>((ref) {
  return ${className}Dao(ref.read(databaseServiceProvider));
});
'''
        : '';

    final dao = '''$imports
class ${className}Dao {
  ${className}Dao(this._db);

  final DatabaseService _db;

  Future<int> insert($className item) async {
    final db = await _db.database;
    return db.insert('$tableName', item.toMap());
  }

  Future<List<$className>> getAll() async {
    final db = await _db.database;
    final maps = await db.query('$tableName');
    return maps.map((m) => $className.fromMap(m)).toList();
  }

  Future<$className?> getById(int id) async {
    final db = await _db.database;
    final maps = await db.query(
      '$tableName',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return $className.fromMap(maps.first);
  }

  Future<int> update($className item) async {
    final db = await _db.database;
    return db.update(
      '$tableName',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete(
      '$tableName',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
$providerSuffix''';

    final dir = Directory(
        p.join(projectPath, 'lib', 'core', 'database', 'dao'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File(p.join(dir.path, '$daoFileName.dart'));
    await file.writeAsString(dao);
  }

  Future<void> _registerInLocator(
    String projectPath,
    String tableName,
    ForgeConfig config,
  ) async {
    final className = _toPascalCase(tableName);
    final daoFileName = '${_toSnakeCase(className)}_dao';
    final appName = _toSnakeCase(config.appName);

    final locatorFile = File(p.join(projectPath, 'lib', 'app', 'locator.dart'));
    if (!await locatorFile.exists()) return;

    var content = await locatorFile.readAsString();
    content = content.replaceAll('\r\n', '\n');

    final importLine =
        "import 'package:$appName/core/database/dao/$daoFileName.dart';";
    final registration =
        'locator.registerLazySingleton<${className}Dao>(() => ${className}Dao(locator<DatabaseService>()));';

    // Skip if already registered
    if (content.contains(registration)) return;

    // Add import after last import
    if (!content.contains(importLine)) {
      final lines = content.split('\n');
      var lastImportIndex = -1;
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('import ')) {
          lastImportIndex = i;
        }
      }
      if (lastImportIndex >= 0) {
        lines.insert(lastImportIndex + 1, importLine);
        content = lines.join('\n');
      }
    }

    // Add registration before closing }
    final closingIndex = content.lastIndexOf('}');
    if (closingIndex >= 0) {
      content =
          '${content.substring(0, closingIndex)}  $registration\n${content.substring(closingIndex)}';
    }

    await locatorFile.writeAsString(content);
  }

  /// Removes a table's model file, DAO file, CREATE TABLE SQL, and DI registration.
  Future<bool> remove(
    String projectPath,
    String tableName,
    ForgeConfig config,
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
    if (!content.contains('CREATE TABLE $tableName(')) {
      stderr.writeln('Error: Table "$tableName" not found in database_service.dart.');
      return false;
    }

    // 1. Remove CREATE TABLE line
    content = content.replaceAll(
      RegExp("    await db\\.execute\\('CREATE TABLE $tableName\\([^)]*\\)'\\);\\n"),
      '',
    );

    await serviceFile.writeAsString(content);

    // 2. Remove DAO registration from locator (for locator-based projects)
    if (config.designPattern != DesignPattern.riverpod &&
        config.modules.contains('locator')) {
      await _removeFromLocator(projectPath, tableName, config);
    }

    // 3. Delete DAO file
    final daoFile = File(p.join(
      projectPath, 'lib', 'core', 'database', 'dao', '${fileName}_dao.dart',
    ));
    if (await daoFile.exists()) {
      await daoFile.delete();
      print('    Deleted lib/core/database/dao/${fileName}_dao.dart');
    }

    // 4. Delete model file
    final modelFile = File(p.join(
      projectPath, 'lib', 'core', 'database', 'models', '$fileName.dart',
    ));
    if (await modelFile.exists()) {
      await modelFile.delete();
      print('    Deleted lib/core/database/models/$fileName.dart');
    }

    // Clean up empty directories
    for (final subDir in ['dao', 'models']) {
      final dir = Directory(
          p.join(projectPath, 'lib', 'core', 'database', subDir));
      if (await dir.exists()) {
        final entries = await dir.list().toList();
        if (entries.isEmpty) {
          await dir.delete();
        }
      }
    }

    return true;
  }

  Future<void> _removeFromLocator(
    String projectPath,
    String tableName,
    ForgeConfig config,
  ) async {
    final className = _toPascalCase(tableName);
    final daoFileName = '${_toSnakeCase(className)}_dao';
    final appName = _toSnakeCase(config.appName);

    final locatorFile = File(p.join(projectPath, 'lib', 'app', 'locator.dart'));
    if (!await locatorFile.exists()) return;

    var content = await locatorFile.readAsString();
    content = content.replaceAll('\r\n', '\n');

    // Remove import
    content = content.replaceAll(
      "import 'package:$appName/core/database/dao/$daoFileName.dart';\n",
      '',
    );

    // Remove registration
    content = content.replaceAll(
      '  locator.registerLazySingleton<${className}Dao>(() => ${className}Dao(locator<DatabaseService>()));\n',
      '',
    );

    // Clean up extra blank lines
    content = content.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    await locatorFile.writeAsString(content);
  }

  static String _toPascalCase(String input) {
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

  static String _toCamelCase(String pascalCase) {
    if (pascalCase.isEmpty) return pascalCase;
    return '${pascalCase[0].toLowerCase()}${pascalCase.substring(1)}';
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
