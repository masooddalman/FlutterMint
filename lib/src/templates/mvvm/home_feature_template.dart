import 'package:flutterforge/src/config/project_config.dart';

class HomeFeatureTemplate {
  HomeFeatureTemplate._();

  static String generateModel(ProjectConfig config) {
    return '''class HomeModel {
  const HomeModel({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}
''';
  }

  static String generateViewModel(ProjectConfig config) {
    final loggerImport = config.hasModule('logging')
        ? "import 'package:${config.appNameSnakeCase}/core/services/logger_service.dart';\n"
        : '';
    final loggerCall = config.hasModule('logging')
        ? "\n    LoggerService.info('Home data loaded');"
        : '';

    return '''import 'package:${config.appNameSnakeCase}/core/base/base_viewmodel.dart';
import 'package:${config.appNameSnakeCase}/features/home/models/home_model.dart';
$loggerImport
class HomeViewModel extends BaseViewModel {
  HomeModel? _homeData;

  HomeModel? get homeData => _homeData;

  Future<void> loadData() async {
    setBusy(true);
    clearError();
    try {
      // Simulate loading data
      await Future.delayed(const Duration(seconds: 1));
      _homeData = const HomeModel(
        title: 'Welcome to ${config.appNamePascalCase}',
        description: 'Your project is set up and ready to go!',
      );$loggerCall
    } catch (e) {
      setError(e.toString());
    } finally {
      setBusy(false);
    }
  }
}
''';
  }

  static String generateView(ProjectConfig config) {
    return '''import 'package:flutter/material.dart';

import 'package:${config.appNameSnakeCase}/core/base/base_view.dart';
import 'package:${config.appNameSnakeCase}/features/home/viewmodels/home_viewmodel.dart';

class HomeView extends BaseView<HomeViewModel> {
  const HomeView({super.key});

  @override
  HomeViewModel createViewModel(BuildContext context) {
    final viewModel = HomeViewModel();
    viewModel.loadData();
    return viewModel;
  }

  @override
  Widget buildView(BuildContext context, HomeViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: _buildBody(viewModel),
    );
  }

  Widget _buildBody(HomeViewModel viewModel) {
    if (viewModel.isBusy) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: Text(
          viewModel.errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    final data = viewModel.homeData;
    if (data == null) {
      return const Center(child: Text('No data'));
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              data.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              data.description,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
''';
  }
}
