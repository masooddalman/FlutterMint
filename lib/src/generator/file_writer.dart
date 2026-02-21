import 'dart:io';

import 'package:path/path.dart' as p;

class FileWriter {
  Future<void> write(String filePath, String content) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> createDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    await dir.create(recursive: true);
  }

  String joinPath(List<String> parts) => p.joinAll(parts);
}
