import 'package:fluttermint/src/config/project_config.dart';

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

  Future<void> initialize() async {
    setLoading();
    await _startupService.initialize();
    switch (_startupService.state) {
      case StartupState.success:
        setSuccess();
      case StartupState.error:
        setError(_startupService.errorMessage ?? 'Initialization failed');
      case StartupState.loading:
        break;
    }
  }

  Future<void> retry() => initialize();
}
''';
  }

  // --- MVI / BLoC variants ---

  static String generateStartupBloc(ProjectConfig config) {
    return '''import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:${config.appNameSnakeCase}/app/startup/startup_event.dart';
import 'package:${config.appNameSnakeCase}/app/startup/startup_service.dart';
import 'package:${config.appNameSnakeCase}/app/startup/startup_state.dart';

class StartupBloc extends Bloc<StartupEvent, StartupBlocState> {
  StartupBloc() : super(const StartupBlocState()) {
    on<StartupInitializeRequested>(_onInitialize);
    on<StartupRetryRequested>(_onRetry);
  }

  final StartupService _startupService = StartupService();

  Future<void> _onInitialize(
    StartupInitializeRequested event,
    Emitter<StartupBlocState> emit,
  ) async {
    emit(state.copyWith(status: StartupStatus.loading));
    await _startupService.initialize();
    switch (_startupService.state) {
      case StartupState.success:
        emit(state.copyWith(status: StartupStatus.success));
      case StartupState.error:
        emit(state.copyWith(
          status: StartupStatus.error,
          errorMessage: _startupService.errorMessage ?? 'Initialization failed',
        ));
      case StartupState.loading:
        break;
    }
  }

  Future<void> _onRetry(
    StartupRetryRequested event,
    Emitter<StartupBlocState> emit,
  ) async {
    await _onInitialize(const StartupInitializeRequested(), emit);
  }
}
''';
  }

  static String generateStartupEvent(ProjectConfig config) {
    return '''import 'package:${config.appNameSnakeCase}/core/base/base_event.dart';

sealed class StartupEvent extends BaseEvent {
  const StartupEvent();
}

final class StartupInitializeRequested extends StartupEvent {
  const StartupInitializeRequested();
}

final class StartupRetryRequested extends StartupEvent {
  const StartupRetryRequested();
}
''';
  }

  static String generateStartupState(ProjectConfig config) {
    return '''import 'package:equatable/equatable.dart';

enum StartupStatus { initial, loading, success, error }

final class StartupBlocState extends Equatable {
  const StartupBlocState({
    this.status = StartupStatus.initial,
    this.errorMessage,
  });

  final StartupStatus status;
  final String? errorMessage;

  StartupBlocState copyWith({
    StartupStatus? status,
    String? errorMessage,
  }) {
    return StartupBlocState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
''';
  }

  static String generateStartupViewMvi(ProjectConfig config) {
    final hasLocator = config.hasModule('locator');
    final locatorImport = hasLocator
        ? "import 'package:${config.appNameSnakeCase}/app/locator.dart';\n"
        : '';
    final createBloc = hasLocator
        ? 'locator<StartupBloc>()'
        : 'StartupBloc()';

    return '''import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:${config.appNameSnakeCase}/app/startup/startup_bloc.dart';
import 'package:${config.appNameSnakeCase}/app/startup/startup_event.dart';
import 'package:${config.appNameSnakeCase}/app/startup/startup_state.dart';
$locatorImport
class StartupView extends StatelessWidget {
  const StartupView({super.key, required this.onReady});

  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => $createBloc..add(const StartupInitializeRequested()),
      child: BlocConsumer<StartupBloc, StartupBlocState>(
        listener: (context, state) {
          if (state.status == StartupStatus.success) {
            onReady();
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: Center(
              child: _buildContent(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, StartupBlocState state) {
    switch (state.status) {
      case StartupStatus.initial:
      case StartupStatus.loading:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('Initializing...'),
          ],
        );
      case StartupStatus.success:
        return const Icon(Icons.check_circle, size: 64, color: Colors.green);
      case StartupStatus.error:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.errorMessage ?? 'An error occurred'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.read<StartupBloc>().add(const StartupRetryRequested()),
              child: const Text('Retry'),
            ),
          ],
        );
    }
  }
}
''';
  }

  // --- Riverpod variants ---

  static String generateStartupNotifier(ProjectConfig config) {
    return '''import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:${config.appNameSnakeCase}/app/startup/startup_service.dart';

enum StartupNotifierState { loading, success, error }

class StartupNotifier extends AsyncNotifier<StartupNotifierState> {
  @override
  Future<StartupNotifierState> build() async {
    final service = StartupService();
    await service.initialize();
    switch (service.state) {
      case StartupState.success:
        return StartupNotifierState.success;
      case StartupState.error:
        throw Exception(service.errorMessage ?? 'Initialization failed');
      case StartupState.loading:
        return StartupNotifierState.loading;
    }
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }
}
''';
  }

  static String generateStartupProviders(ProjectConfig config) {
    return '''import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:${config.appNameSnakeCase}/app/startup/startup_notifier.dart';

final startupNotifierProvider =
    AsyncNotifierProvider<StartupNotifier, StartupNotifierState>(
  StartupNotifier.new,
);
''';
  }

  static String generateStartupViewRiverpod(ProjectConfig config) {
    return '''import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:${config.appNameSnakeCase}/app/startup/startup_providers.dart';

class StartupView extends ConsumerWidget {
  const StartupView({super.key, required this.onReady});

  final VoidCallback onReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(startupNotifierProvider);

    ref.listen(startupNotifierProvider, (_, next) {
      if (next.hasValue) {
        onReady();
      }
    });

    return Scaffold(
      body: Center(
        child: state.when(
          loading: () => const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text('Initializing...'),
            ],
          ),
          error: (error, _) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(error.toString()),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    ref.read(startupNotifierProvider.notifier).retry(),
                child: const Text('Retry'),
              ),
            ],
          ),
          data: (_) =>
              const Icon(Icons.check_circle, size: 64, color: Colors.green),
        ),
      ),
    );
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

import 'package:${config.appNameSnakeCase}/core/base/base_viewmodel.dart';
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
          if (viewModel.state == ViewState.success) {
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
    switch (viewModel.state) {
      case ViewState.initial:
      case ViewState.loading:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('Initializing...'),
          ],
        );
      case ViewState.success:
        return const Icon(Icons.check_circle, size: 64, color: Colors.green);
      case ViewState.error:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(viewModel.errorMessage ?? 'An error occurred'),
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
