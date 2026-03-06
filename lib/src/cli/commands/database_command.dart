import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:fluttermint/src/cli/prompts/prompt_utils.dart';
import 'package:fluttermint/src/config/forge_config.dart';
import 'package:fluttermint/src/generator/database_generator.dart';

class DatabaseCommand extends Command<void> {
  DatabaseCommand() {
    addSubcommand(_DbAddCommand());
    addSubcommand(_DbRemoveCommand());
  }

  @override
  final String name = 'db';

  @override
  final String description = 'Manage local database tables.';
}

class _DbAddCommand extends Command<void> {
  _DbAddCommand() {
    argParser.addMultiOption(
      'col',
      abbr: 'c',
      help: 'Column definition as name:Type (e.g. name:String, age:int)',
    );
  }

  @override
  final String name = 'add';

  @override
  final String description =
      'Add a database table with model and CRUD methods.\n'
      'Usage: fluttermint db add <table> --col name:String --col age:int\n'
      'Example: fluttermint db add users -c name:String -c email:String -c age:int';

  @override
  Future<void> run() async {
    final projectPath = Directory.current.path;

    final forgeConfig = ForgeConfig.load(projectPath);
    if (forgeConfig == null) {
      stderr.writeln(
        'Error: No FlutterMint project found in the current directory.',
      );
      stderr.writeln(
        'Make sure you are inside a project created with "fluttermint create".',
      );
      return;
    }

    if (!forgeConfig.modules.contains('database')) {
      stderr.writeln('Error: Database module is not installed.');
      stderr.writeln('Run "fluttermint add database" first.');
      return;
    }

    // Get table name
    final rest = argResults?.rest ?? [];
    String tableName;

    if (rest.isEmpty) {
      tableName = PromptUtils.askText(
        'Enter table name (snake_case, e.g. users, order_items)',
      );
    } else {
      tableName = rest.first;
    }

    // Validate table name
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(tableName)) {
      stderr.writeln('Error: "$tableName" is not a valid table name.');
      stderr.writeln(
          'Use snake_case (e.g. users, order_items, product_categories).');
      return;
    }

    // Get columns
    final colArgs = argResults?['col'] as List<String>? ?? [];
    final columns = <ColumnDef>[];

    if (colArgs.isEmpty) {
      // Interactive mode
      print('Define columns (enter empty name to finish):');
      while (true) {
        final colName = PromptUtils.askText('  Column name');
        if (colName.isEmpty) break;

        final typeChoice = PromptUtils.askChoice(
          '  Type for "$colName"',
          DatabaseGenerator.supportedTypes,
        );
        final type = DatabaseGenerator.supportedTypes[typeChoice - 1];
        columns.add(ColumnDef(colName, type));
      }
    } else {
      // Parse --col arguments
      for (final col in colArgs) {
        final parts = col.split(':');
        if (parts.length != 2) {
          stderr.writeln('Error: Invalid column "$col". Use name:Type format.');
          return;
        }
        final name = parts[0];
        final type = parts[1];

        if (!DatabaseGenerator.supportedTypes.contains(type)) {
          stderr.writeln('Error: Unsupported type "$type" for column "$name".');
          stderr.writeln(
            'Supported types: ${DatabaseGenerator.supportedTypes.join(', ')}',
          );
          return;
        }
        columns.add(ColumnDef(name, type));
      }
    }

    if (columns.isEmpty) {
      stderr.writeln('Error: At least one column is required.');
      return;
    }

    print('');
    final generator = DatabaseGenerator();
    final success =
        await generator.generate(projectPath, tableName, columns, forgeConfig);

    if (success) {
      final className = _toPascalCase(tableName);
      final snakeName = _toSnakeCase(className);
      print('  Created table: $tableName');
      print('  Model: lib/core/database/models/$snakeName.dart');
      print('  DAO:   lib/core/database/dao/${snakeName}_dao.dart');
      print('');
      print('Usage:');
      print('  final dao = locator<${className}Dao>();');
      print('  await dao.insert($className(...));');
      print('  await dao.getAll();');
      print('  await dao.getById(1);');
      print('  await dao.update($className(...));');
      print('  await dao.delete(1);');
      print('');
    }
  }

}

class _DbRemoveCommand extends Command<void> {
  @override
  final String name = 'remove';

  @override
  final String description =
      'Remove a database table, its model, and CRUD methods.\n'
      'Usage: fluttermint db remove <table>\n'
      'Example: fluttermint db remove users';

  @override
  Future<void> run() async {
    final projectPath = Directory.current.path;

    final forgeConfig = ForgeConfig.load(projectPath);
    if (forgeConfig == null) {
      stderr.writeln(
        'Error: No FlutterMint project found in the current directory.',
      );
      return;
    }

    if (!forgeConfig.modules.contains('database')) {
      stderr.writeln('Error: Database module is not installed.');
      return;
    }

    final rest = argResults?.rest ?? [];
    String tableName;

    if (rest.isEmpty) {
      tableName = PromptUtils.askText('Enter table name to remove');
    } else {
      tableName = rest.first;
    }

    final confirm = PromptUtils.askYesNo(
      'Remove table "$tableName" and all its CRUD methods?',
      defaultValue: false,
    );
    if (!confirm) {
      print('Cancelled.');
      return;
    }

    print('');
    final generator = DatabaseGenerator();
    final success = await generator.remove(projectPath, tableName, forgeConfig);

    if (success) {
      print('  Removed table: $tableName');
      print('  Cleaned up: CREATE TABLE, model file, DAO file');
      print('');
    }
  }
}

String _toPascalCase(String input) {
  var name = input;
  if (name.endsWith('ies')) {
    name = '${name.substring(0, name.length - 3)}y';
  } else if (name.endsWith('ses') ||
      name.endsWith('xes') ||
      name.endsWith('zes')) {
    name = name.substring(0, name.length - 2);
  } else if (name.endsWith('s') && !name.endsWith('ss')) {
    name = name.substring(0, name.length - 1);
  }
  return name
      .split('_')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join();
}

String _toSnakeCase(String input) {
  return input
      .replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => '_${match.group(0)!.toLowerCase()}',
      )
      .replaceFirst(RegExp(r'^_'), '');
}
