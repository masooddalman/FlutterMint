import 'package:fluttermint/src/config/project_config.dart';

class DatabaseTemplate {
  DatabaseTemplate._();

  static String generateDatabaseService(ProjectConfig config) {
    return '''import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), '${config.appNameSnakeCase}.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Add table creation here
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  // Add more tables here
}
''';
  }

  static String generateDatabaseProviders(ProjectConfig config) {
    return '''import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:${config.appNameSnakeCase}/core/database/database_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});
''';
  }
}
