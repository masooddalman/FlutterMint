import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:flutterforge/src/modules/module.dart';

class PubspecEditor {
  Future<void> addDependencies(
    String projectPath,
    List<Module> modules,
  ) async {
    final pubspecPath = p.join(projectPath, 'pubspec.yaml');
    final file = File(pubspecPath);
    var content = await file.readAsString();

    final deps = <String, String>{};
    final devDeps = <String, String>{};

    for (final module in modules) {
      deps.addAll(module.dependencies);
      devDeps.addAll(module.devDependencies);
    }

    if (deps.isNotEmpty) {
      content = _insertDependencies(content, 'dependencies:', deps);
    }
    if (devDeps.isNotEmpty) {
      content = _insertDependencies(content, 'dev_dependencies:', devDeps);
    }

    await file.writeAsString(content);
  }

  String _insertDependencies(
    String content,
    String section,
    Map<String, String> deps,
  ) {
    final lines = content.split('\n');
    final sectionIndex = lines.indexWhere((l) => l.trimRight() == section);

    if (sectionIndex == -1) {
      // Section doesn't exist, append it
      final newLines = <String>[section];
      for (final entry in deps.entries) {
        newLines.add('  ${entry.key}: ${entry.value}');
      }
      lines.addAll(['', ...newLines]);
      return lines.join('\n');
    }

    // Find the end of this section (next top-level key or end of file)
    var insertIndex = sectionIndex + 1;
    while (insertIndex < lines.length) {
      final line = lines[insertIndex];
      if (line.isNotEmpty &&
          !line.startsWith(' ') &&
          !line.startsWith('#')) {
        break;
      }
      insertIndex++;
    }

    // Insert new dependencies before the next section
    final newLines = <String>[];
    for (final entry in deps.entries) {
      final depLine = '  ${entry.key}: ${entry.value}';
      // Only add if not already present
      if (!lines.any((l) => l.trim().startsWith('${entry.key}:'))) {
        newLines.add(depLine);
      }
    }

    if (newLines.isNotEmpty) {
      lines.insertAll(insertIndex, newLines);
    }

    return lines.join('\n');
  }
}
