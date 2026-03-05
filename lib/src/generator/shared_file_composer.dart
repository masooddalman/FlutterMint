import 'package:path/path.dart' as p;

import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/generator/file_writer.dart';
import 'package:fluttermint/src/modules/module.dart';
import 'package:fluttermint/src/templates/core/app_template.dart';
import 'package:fluttermint/src/templates/core/locator_template.dart';
import 'package:fluttermint/src/templates/core/main_template.dart';

class SharedFileComposer {
  final FileWriter _fileWriter = FileWriter();

  Future<void> compose(
    String projectPath,
    ProjectConfig config,
    List<Module> modules,
  ) async {
    await _composeMainDart(projectPath, config, modules);
    await _composeAppDart(projectPath, config, modules);

    if (config.hasModule('locator')) {
      await _composeLocatorDart(projectPath, config, modules);
    }

  }

  Future<void> _composeMainDart(
    String projectPath,
    ProjectConfig config,
    List<Module> modules,
  ) async {
    final imports = <String>[];
    final setupLines = <String>[];
    final overrides = <String>[];

    for (final module in modules) {
      imports.addAll(module.mainImports(config));
      setupLines.addAll(module.mainSetupLines(config));
      overrides.addAll(module.mainProviderOverrides(config));
    }

    final content = MainTemplate.generate(
      config: config,
      imports: imports,
      setupLines: setupLines,
      overrides: overrides,
    );

    await _fileWriter.write(
      p.join(projectPath, 'lib', 'main.dart'),
      content,
    );
  }

  Future<void> _composeAppDart(
    String projectPath,
    ProjectConfig config,
    List<Module> modules,
  ) async {
    final imports = <String>[];
    final providerDeclarations = <String>[];

    for (final module in modules) {
      imports.addAll(module.appImports(config));
      providerDeclarations.addAll(module.providerDeclarations(config));
    }

    final content = AppTemplate.generate(
      config: config,
      imports: imports,
      providerDeclarations: providerDeclarations,
    );

    await _fileWriter.write(
      p.join(projectPath, 'lib', 'app', 'app.dart'),
      content,
    );
  }

  Future<void> _composeLocatorDart(
    String projectPath,
    ProjectConfig config,
    List<Module> modules,
  ) async {
    final imports = <String>[];
    final registrations = <String>[];

    for (final module in modules) {
      imports.addAll(module.locatorImports(config));
      registrations.addAll(module.locatorRegistrations(config));
    }

    final content = LocatorTemplate.generate(
      config: config,
      imports: imports,
      registrations: registrations,
    );

    await _fileWriter.write(
      p.join(projectPath, 'lib', 'app', 'locator.dart'),
      content,
    );
  }
}
