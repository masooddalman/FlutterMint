import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/modules/module.dart';

/// Incrementally injects or removes a module's contributions from shared files
/// (main.dart, app.dart, locator.dart) without destroying user edits.
///
/// Used by [ModuleAdder] and [ModuleRemover] instead of full recomposition.
class SharedFileUpdater {
  /// Injects a module's contributions into existing shared files.
  Future<void> injectModule(
    String projectPath,
    ProjectConfig config,
    Module module,
  ) async {
    await _injectLocator(projectPath, config, module);
    await _injectMain(projectPath, config, module);
    await _injectApp(projectPath, config, module);
  }

  /// Removes a module's contributions from existing shared files.
  Future<void> removeModule(
    String projectPath,
    ProjectConfig config,
    Module module,
  ) async {
    await _removeFromLocator(projectPath, config, module);
    await _removeFromMain(projectPath, config, module);
    await _removeFromApp(projectPath, config, module);
  }

  // ---------------------------------------------------------------------------
  // Inject helpers
  // ---------------------------------------------------------------------------

  Future<void> _injectLocator(
    String projectPath,
    ProjectConfig config,
    Module module,
  ) async {
    final imports = module.locatorImports(config);
    final registrations = module.locatorRegistrations(config);
    if (imports.isEmpty && registrations.isEmpty) return;

    final file = File(p.join(projectPath, 'lib', 'app', 'locator.dart'));
    if (!await file.exists()) return;

    var content = await file.readAsString();

    // Skip if already injected
    if (registrations.isNotEmpty && content.contains(registrations.first)) {
      return;
    }

    content = _injectImports(content, imports);
    content = _injectBeforeClosingBrace(content, registrations);

    await file.writeAsString(content);
  }

  Future<void> _injectMain(
    String projectPath,
    ProjectConfig config,
    Module module,
  ) async {
    final imports = module.mainImports(config);
    final setupLines = module.mainSetupLines(config);
    final overrides = module.mainProviderOverrides(config);
    if (imports.isEmpty && setupLines.isEmpty && overrides.isEmpty) return;

    final file = File(p.join(projectPath, 'lib', 'main.dart'));
    if (!await file.exists()) return;

    var content = await file.readAsString();

    // Skip if already injected
    if (setupLines.isNotEmpty && content.contains(setupLines.first)) return;

    content = _injectImports(content, imports);

    // Add setup lines before runApp(
    if (setupLines.isNotEmpty) {
      final runAppIndex = content.indexOf('runApp(');
      if (runAppIndex >= 0) {
        final insertion =
            '${setupLines.map((l) => '  $l').join('\n')}\n\n';
        content =
            '${content.substring(0, runAppIndex)}$insertion${content.substring(runAppIndex)}';
      }
    }

    // Add provider overrides into ProviderScope
    if (overrides.isNotEmpty) {
      content = _injectProviderOverrides(content, overrides);
    }

    await file.writeAsString(content);
  }

  Future<void> _injectApp(
    String projectPath,
    ProjectConfig config,
    Module module,
  ) async {
    final imports = module.appImports(config);
    final providers = module.providerDeclarations(config);
    if (imports.isEmpty && providers.isEmpty) return;

    final file = File(p.join(projectPath, 'lib', 'app', 'app.dart'));
    if (!await file.exists()) return;

    var content = await file.readAsString();

    // Skip if already present
    if (providers.isNotEmpty && content.contains(providers.first)) return;

    content = _injectImports(content, imports);

    if (providers.isNotEmpty) {
      content = _injectProviders(content, providers);
    }

    await file.writeAsString(content);
  }

  // ---------------------------------------------------------------------------
  // Remove helpers
  // ---------------------------------------------------------------------------

  Future<void> _removeFromLocator(
    String projectPath,
    ProjectConfig config,
    Module module,
  ) async {
    final imports = module.locatorImports(config);
    final registrations = module.locatorRegistrations(config);
    if (imports.isEmpty && registrations.isEmpty) return;

    final file = File(p.join(projectPath, 'lib', 'app', 'locator.dart'));
    if (!await file.exists()) return;

    var content = await file.readAsString();

    for (final imp in imports) {
      content = content.replaceAll("import '$imp';\n", '');
    }
    for (final reg in registrations) {
      content = content.replaceAll('  $reg\n', '');
    }

    content = _cleanBlankLines(content);
    await file.writeAsString(content);
  }

  Future<void> _removeFromMain(
    String projectPath,
    ProjectConfig config,
    Module module,
  ) async {
    final imports = module.mainImports(config);
    final setupLines = module.mainSetupLines(config);
    final overrides = module.mainProviderOverrides(config);
    if (imports.isEmpty && setupLines.isEmpty && overrides.isEmpty) return;

    final file = File(p.join(projectPath, 'lib', 'main.dart'));
    if (!await file.exists()) return;

    var content = await file.readAsString();

    for (final imp in imports) {
      content = content.replaceAll("import '$imp';\n", '');
    }
    for (final line in setupLines) {
      content = content.replaceAll('  $line\n', '');
    }

    // Remove provider overrides
    if (overrides.isNotEmpty) {
      for (final override in overrides) {
        content = content.replaceAll('        $override,\n', '');
      }

      // If overrides block is now empty, revert to const ProviderScope
      if (content.contains('overrides: [\n      ],')) {
        content = content.replaceFirst(
          RegExp(
            r'runApp\(\s*ProviderScope\(\s*overrides:\s*\[\s*\],\s*child:\s*const\s+(\w+App\(\)),\s*\),\s*\);',
          ),
          'runApp(const ProviderScope(child: \$1));',
        );
      }
    }

    content = _cleanBlankLines(content);
    await file.writeAsString(content);
  }

  Future<void> _removeFromApp(
    String projectPath,
    ProjectConfig config,
    Module module,
  ) async {
    final imports = module.appImports(config);
    final providers = module.providerDeclarations(config);
    if (imports.isEmpty && providers.isEmpty) return;

    final file = File(p.join(projectPath, 'lib', 'app', 'app.dart'));
    if (!await file.exists()) return;

    var content = await file.readAsString();

    for (final imp in imports) {
      content = content.replaceAll("import '$imp';\n", '');
    }

    // Remove provider lines from MultiProvider
    for (final provider in providers) {
      content = content.replaceAll('        $provider\n', '');
    }

    // If MultiProvider has no more providers, unwrap it
    if (content.contains('providers: [\n      ],')) {
      // Extract the child widget and replace MultiProvider with just the child
      final multiProviderRegex = RegExp(
        r'MultiProvider\(\s*providers:\s*\[\s*\],\s*child:\s*Builder\(\s*builder:\s*\(context\)\s*\{\s*return\s+(.*?);\s*\},\s*\),\s*\)',
        dotAll: true,
      );
      final match = multiProviderRegex.firstMatch(content);
      if (match != null) {
        content = content.replaceFirst(multiProviderRegex, match.group(1)!);
        // Also remove the provider import if no longer needed
        content =
            content.replaceAll("import 'package:provider/provider.dart';\n", '');
      }
    }

    content = _cleanBlankLines(content);
    await file.writeAsString(content);
  }

  // ---------------------------------------------------------------------------
  // Shared utility methods
  // ---------------------------------------------------------------------------

  /// Inserts import lines after the last existing import statement.
  String _injectImports(String content, List<String> newImports) {
    if (newImports.isEmpty) return content;

    final lines = content.split('\n');
    var lastImportIndex = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].startsWith('import ')) {
        lastImportIndex = i;
      }
    }

    if (lastImportIndex >= 0) {
      final importLines = newImports
          .where((imp) => !content.contains("import '$imp';"))
          .map((imp) => "import '$imp';")
          .toList();
      if (importLines.isNotEmpty) {
        lines.insertAll(lastImportIndex + 1, importLines);
      }
    }

    return lines.join('\n');
  }

  /// Inserts lines before the last closing brace in the content
  /// (typically the closing `}` of `setupLocator()`).
  String _injectBeforeClosingBrace(String content, List<String> newLines) {
    if (newLines.isEmpty) return content;

    final closingIndex = content.lastIndexOf('}');
    if (closingIndex < 0) return content;

    final insertion = '${newLines.map((l) => '  $l').join('\n')}\n';
    return '${content.substring(0, closingIndex)}$insertion${content.substring(closingIndex)}';
  }

  /// Injects provider overrides into an existing ProviderScope in main.dart.
  ///
  /// If `ProviderScope(overrides: [...])` exists, adds to the list.
  /// If `const ProviderScope(child: ...)` exists, converts to non-const with overrides.
  String _injectProviderOverrides(String content, List<String> overrides) {
    if (overrides.isEmpty) return content;

    // Case 1: overrides block already exists — add to it
    if (content.contains('overrides: [')) {
      final marker = 'overrides: [\n';
      final index = content.indexOf(marker);
      if (index >= 0) {
        final insertAt = index + marker.length;
        final insertion =
            '${overrides.map((o) => '        $o,').join('\n')}\n';
        return '${content.substring(0, insertAt)}$insertion${content.substring(insertAt)}';
      }
    }

    // Case 2: const ProviderScope(child: ...) — convert to overrides variant
    final constPsRegex = RegExp(
      r'runApp\(const ProviderScope\(child: (\w+App\(\))\)\);',
    );
    final match = constPsRegex.firstMatch(content);
    if (match != null) {
      final appWidget = match.group(1)!;
      final overrideBlock =
          overrides.map((o) => '        $o,').join('\n');
      final replacement = '''runApp(
    ProviderScope(
      overrides: [
$overrideBlock
      ],
      child: const $appWidget,
    ),
  );''';
      return content.replaceFirst(constPsRegex, replacement);
    }

    return content;
  }

  /// Injects provider declarations into an existing MultiProvider in app.dart.
  ///
  /// If MultiProvider exists, adds to the providers list.
  /// If no MultiProvider, wraps the existing widget return in a MultiProvider.
  String _injectProviders(String content, List<String> providers) {
    if (providers.isEmpty) return content;

    // Case 1: MultiProvider already exists — add to providers list
    if (content.contains('providers: [')) {
      final marker = 'providers: [\n';
      final index = content.indexOf(marker);
      if (index >= 0) {
        final insertAt = index + marker.length;
        final insertion =
            '${providers.map((p) => '        $p').join('\n')}\n';
        return '${content.substring(0, insertAt)}$insertion${content.substring(insertAt)}';
      }
    }

    // Case 2: No MultiProvider — wrap the return statement
    // Find `return MaterialApp` and wrap it
    final returnRegex = RegExp(r'return (MaterialApp[\s\S]*?\));', dotAll: true);
    final match = returnRegex.firstMatch(content);
    if (match != null) {
      final materialApp = match.group(1)!;
      final providerLines = providers.map((p) => '        $p').join('\n');
      final wrapped = '''return MultiProvider(
      providers: [
$providerLines
      ],
      child: Builder(
        builder: (context) {
          return $materialApp;
        },
      ),
    );''';

      // Add provider import if not present
      if (!content.contains("import 'package:provider/provider.dart';")) {
        content = _injectImports(
            content, ['package:provider/provider.dart']);
      }

      return content.replaceFirst(
          'return ${match.group(1)!});', wrapped);
    }

    return content;
  }

  /// Removes runs of 3+ consecutive newlines, replacing with double newlines.
  String _cleanBlankLines(String content) {
    return content.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }
}
