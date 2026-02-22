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
    final sdkDeps = <String, String>{};

    for (final module in modules) {
      deps.addAll(module.dependencies);
      devDeps.addAll(module.devDependencies);
      sdkDeps.addAll(module.sdkDependencies);
    }

    if (deps.isNotEmpty || sdkDeps.isNotEmpty) {
      content = _insertDependencies(content, 'dependencies:', deps, sdkDeps);
    }
    if (devDeps.isNotEmpty) {
      content = _insertDependencies(content, 'dev_dependencies:', devDeps, {});
    }

    // Add generate: true under flutter: section if localization is selected
    final hasLocalization =
        modules.any((m) => m.id == 'localization');
    if (hasLocalization) {
      content = _addGenerateFlag(content);
    }

    await file.writeAsString(content);
  }

  String _addGenerateFlag(String content) {
    final lines = content.split('\n');
    final flutterIndex =
        lines.indexWhere((l) => l.trimRight() == 'flutter:');
    if (flutterIndex == -1) return content;

    // Check if generate: true already exists
    if (lines.any((l) => l.trim() == 'generate: true')) return content;

    // Insert generate: true right after flutter:
    lines.insert(flutterIndex + 1, '  generate: true');
    return lines.join('\n');
  }

  String _insertDependencies(
    String content,
    String section,
    Map<String, String> deps,
    Map<String, String> sdkDeps,
  ) {
    final lines = content.split('\n');
    final sectionIndex = lines.indexWhere((l) => l.trimRight() == section);

    if (sectionIndex == -1) {
      // Section doesn't exist, append it
      final newLines = <String>[section];
      for (final entry in deps.entries) {
        newLines.add('  ${entry.key}: ${entry.value}');
      }
      for (final entry in sdkDeps.entries) {
        newLines.add('  ${entry.key}:');
        newLines.add('    sdk: ${entry.value}');
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
      if (!lines.any((l) => l.trim().startsWith('${entry.key}:'))) {
        newLines.add('  ${entry.key}: ${entry.value}');
      }
    }
    for (final entry in sdkDeps.entries) {
      if (!lines.any((l) => l.trim().startsWith('${entry.key}:'))) {
        newLines.add('  ${entry.key}:');
        newLines.add('    sdk: ${entry.value}');
      }
    }

    if (newLines.isNotEmpty) {
      lines.insertAll(insertIndex, newLines);
    }

    return lines.join('\n');
  }
}
