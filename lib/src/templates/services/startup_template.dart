import 'package:flutterforge/src/config/project_config.dart';

class StartupTemplate {
  StartupTemplate._();

  static String generateStartupService(ProjectConfig config) {
    final logImport = config.hasModule('logging')
        ? "import 'package:${config.appNameSnakeCase}/core/services/logger_service.dart';\n"
        : '';
    final logStart = config.hasModule('logging')
        ? "    LoggerService.info('Starting app initialization...');\n"
        : '';
    final logDone = config.hasModule('logging')
        ? "    LoggerService.info('App initialization complete');\n"
        : '';
    final logError = config.hasModule('logging')
        ? "    LoggerService.error('Startup failed', error: e, stackTrace: s);\n"
        : '';

    return '''import 'dart:async';

$logImport
enum StartupState { loading, success, error }

class StartupService {
  StartupState _state = StartupState.loading;
  String? _errorMessage;

  StartupState get state => _state;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _state = StartupState.loading;
    _errorMessage = null;
$logStart
    try {
      // Add your initialization steps here
      await _initStep1();
      await _initStep2();

      _state = StartupState.success;
$logDone    } catch (e, s) {
      _state = StartupState.error;
      _errorMessage = e.toString();
$logError    }
  }

  Future<void> _initStep1() async {
    // Example: Load configuration, check connectivity, etc.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _initStep2() async {
    // Example: Authenticate user, sync data, etc.
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
''';
  }

  static String generateStartupViewModel(ProjectConfig config) {
    return '''import 'package:${config.appNameSnakeCase}/core/base/base_viewmodel.dart';
import 'package:${config.appNameSnakeCase}/app/startup/startup_service.dart';

class StartupViewModel extends BaseViewModel {
  final StartupService _startupService = StartupService();

  StartupState get startupState => _startupService.state;
  String? get startupError => _startupService.errorMessage;

  Future<void> initialize() async {
    setBusy(true);
    await _startupService.initialize();
    setBusy(false);
  }

  Future<void> retry() async {
    clearError();
    await initialize();
  }
}
''';
  }

  static String generateStartupView(ProjectConfig config) {
    final hasLocator = config.hasModule('locator');
    final locatorImport = hasLocator
        ? "import 'package:${config.appNameSnakeCase}/app/locator.dart';\n"
        : '';
    final createVm = hasLocator
        ? 'locator<StartupViewModel>()'
        : 'StartupViewModel()';

    return '''import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:${config.appNameSnakeCase}/app/startup/startup_service.dart';
import 'package:${config.appNameSnakeCase}/app/startup/startup_viewmodel.dart';
$locatorImport
class StartupView extends StatelessWidget {
  const StartupView({super.key, required this.onReady});

  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final viewModel = $createVm;
        viewModel.initialize().then((_) {
          if (viewModel.startupState == StartupState.success) {
            onReady();
          }
        });
        return viewModel;
      },
      child: Consumer<StartupViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            body: Center(
              child: _buildContent(viewModel),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(StartupViewModel viewModel) {
    switch (viewModel.startupState) {
      case StartupState.loading:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('Initializing...'),
          ],
        );
      case StartupState.success:
        return const Icon(Icons.check_circle, size: 64, color: Colors.green);
      case StartupState.error:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(viewModel.startupError ?? 'An error occurred'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: viewModel.retry,
              child: const Text('Retry'),
            ),
          ],
        );
    }
  }
}
''';
  }
}
