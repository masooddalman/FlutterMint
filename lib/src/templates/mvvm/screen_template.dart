import 'package:flutterforge/src/config/project_config.dart';

class ScreenTemplate {
  ScreenTemplate._();

  static String generateModel(String name, ProjectConfig config) {
    final pascal = ProjectConfig.toPascalCase(name);

    return '''class ${pascal}Model {
  const ${pascal}Model();
}
''';
  }

  static String generateRepository(String name, ProjectConfig config) {
    final pascal = ProjectConfig.toPascalCase(name);

    return '''import 'package:${config.appNameSnakeCase}/features/$name/models/${name}_model.dart';

abstract class ${pascal}Repository {
  Future<${pascal}Model> getData();
}
''';
  }

  static String generateRepositoryImpl(String name, ProjectConfig config) {
    final pascal = ProjectConfig.toPascalCase(name);
    final loggerImport = config.hasModule('logging')
        ? "import 'package:${config.appNameSnakeCase}/core/services/logger_service.dart';\n"
        : '';
    final loggerCall = config.hasModule('logging')
        ? "\n    LoggerService.info('$pascal data fetched');"
        : '';

    return '''import 'package:${config.appNameSnakeCase}/domain/repositories/${name}_repository.dart';
import 'package:${config.appNameSnakeCase}/features/$name/models/${name}_model.dart';
$loggerImport
class ${pascal}RepositoryImpl implements ${pascal}Repository {
  @override
  Future<${pascal}Model> getData() async {
    // TODO: implement data fetching$loggerCall
    return const ${pascal}Model();
  }
}
''';
  }

  static String generateUseCase(String name, ProjectConfig config) {
    final pascal = ProjectConfig.toPascalCase(name);

    return '''import 'package:${config.appNameSnakeCase}/domain/repositories/${name}_repository.dart';
import 'package:${config.appNameSnakeCase}/features/$name/models/${name}_model.dart';

class Get${pascal}DataUseCase {
  Get${pascal}DataUseCase(this._repository);

  final ${pascal}Repository _repository;

  Future<${pascal}Model> call() => _repository.getData();
}
''';
  }

  static String generateViewModel(String name, ProjectConfig config) {
    final pascal = ProjectConfig.toPascalCase(name);
    final loggerImport = config.hasModule('logging')
        ? "import 'package:${config.appNameSnakeCase}/core/services/logger_service.dart';\n"
        : '';
    final loggerCall = config.hasModule('logging')
        ? "\n      LoggerService.info('$pascal data loaded');"
        : '';

    return '''import 'package:${config.appNameSnakeCase}/core/base/base_viewmodel.dart';
import 'package:${config.appNameSnakeCase}/domain/usecases/get_${name}_data_usecase.dart';
import 'package:${config.appNameSnakeCase}/features/$name/models/${name}_model.dart';
$loggerImport
class ${pascal}ViewModel extends BaseViewModel {
  ${pascal}ViewModel(this._getData);

  final Get${pascal}DataUseCase _getData;

  ${pascal}Model? _data;

  ${pascal}Model? get data => _data;

  Future<void> loadData() async {
    setLoading();
    try {
      _data = await _getData();$loggerCall
      setSuccess();
    } catch (e) {
      setError(e.toString());
    }
  }
}
''';
  }

  static String generateView(
    String name,
    ProjectConfig config, {
    Map<String, String> params = const {},
  }) {
    final pascal = ProjectConfig.toPascalCase(name);
    final hasLocator = config.hasModule('locator');

    final locatorImport = hasLocator
        ? "import 'package:${config.appNameSnakeCase}/app/locator.dart';\n"
        : '';
    final nonLocatorImports = hasLocator
        ? ''
        : "import 'package:${config.appNameSnakeCase}/data/repositories/${name}_repository.dart';\n"
            "import 'package:${config.appNameSnakeCase}/domain/usecases/get_${name}_data_usecase.dart';\n";

    final createVm = hasLocator
        ? 'locator<${pascal}ViewModel>()..loadData()'
        : '${pascal}ViewModel(Get${pascal}DataUseCase(${pascal}RepositoryImpl()))..loadData()';

    final title = _toTitleCase(name);

    // Constructor params
    final hasParams = params.isNotEmpty;
    final constPrefix = hasParams ? '' : 'const ';
    final fieldDeclarations = params.entries
        .map((e) => '  final ${e.value} ${e.key};')
        .join('\n');
    final constructorParams = params.keys
        .map((k) => 'required this.$k')
        .join(', ');
    final constructor = hasParams
        ? '  const ${pascal}View({super.key, $constructorParams});'
        : '  const ${pascal}View({super.key});';
    final fieldsBlock = hasParams ? '$fieldDeclarations\n\n$constructor' : constructor;

    return '''import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:${config.appNameSnakeCase}/core/base/base_viewmodel.dart';
import 'package:${config.appNameSnakeCase}/features/$name/viewmodels/${name}_viewmodel.dart';
$locatorImport$nonLocatorImports
class ${pascal}View extends StatelessWidget {
$fieldsBlock

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => $createVm,
      child: Consumer<${pascal}ViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: ${constPrefix}Text('$title'),
            ),
            body: _buildBody(context, viewModel),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, ${pascal}ViewModel viewModel) {
    switch (viewModel.state) {
      case ViewState.initial:
      case ViewState.loading:
        return const Center(child: CircularProgressIndicator());
      case ViewState.error:
        return Center(
          child: Text(
            viewModel.errorMessage ?? 'An error occurred',
            style: const TextStyle(color: Colors.red),
          ),
        );
      case ViewState.success:
        return const Center(
          child: Text('$title screen'),
        );
    }
  }
}
''';
  }

  static String generateSharedWidgetsPlaceholder() {
    return '''// Shared widgets go here.
// Place reusable widgets that are used across multiple screens in this folder.
''';
  }

  static String _toTitleCase(String input) {
    return input
        .replaceAll(RegExp(r'[-_]+'), ' ')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1).toLowerCase())
        .join(' ');
  }
}
