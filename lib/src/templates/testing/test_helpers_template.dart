import 'package:fluttermint/src/config/project_config.dart';

class TestHelpersTemplate {
  TestHelpersTemplate._();

  static String generateTestHelpers(ProjectConfig config) {
    return '''import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:${config.appNameSnakeCase}/domain/repositories/home_repository.dart';
import 'package:${config.appNameSnakeCase}/domain/usecases/get_home_data_usecase.dart';
import 'package:${config.appNameSnakeCase}/features/home/models/home_model.dart';

// --- Mocks ---

class MockHomeRepository extends Mock implements HomeRepository {}

class MockGetHomeDataUseCase extends Mock implements GetHomeDataUseCase {}

// --- Test data ---

const testHomeModel = HomeModel();

// --- Widget helpers ---

/// Wraps a widget with MaterialApp for testing
Widget createTestableWidget(Widget child) {
  return MaterialApp(
    home: child,
  );
}

/// Pumps a widget and waits for animations to settle
Future<void> pumpAndSettle(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(createTestableWidget(widget));
  await tester.pumpAndSettle();
}

/// Helper to find widgets by type
Finder findByType<T>() => find.byType(T);

/// Helper to find widgets by text
Finder findByText(String text) => find.text(text);

/// Helper to tap a widget and settle
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
''';
  }

  static String generateTestHelpersMvi(ProjectConfig config) {
    return '''import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:${config.appNameSnakeCase}/domain/repositories/home_repository.dart';
import 'package:${config.appNameSnakeCase}/domain/usecases/get_home_data_usecase.dart';
import 'package:${config.appNameSnakeCase}/features/home/models/home_model.dart';

// --- Mocks ---

class MockHomeRepository extends Mock implements HomeRepository {}

class MockGetHomeDataUseCase extends Mock implements GetHomeDataUseCase {}

// --- Test data ---

const testHomeModel = HomeModel();

// --- Widget helpers ---

/// Wraps a widget with MaterialApp for testing
Widget createTestableWidget(Widget child) {
  return MaterialApp(
    home: child,
  );
}

/// Pumps a widget and waits for animations to settle
Future<void> pumpAndSettle(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(createTestableWidget(widget));
  await tester.pumpAndSettle();
}

/// Helper to find widgets by type
Finder findByType<T>() => find.byType(T);

/// Helper to find widgets by text
Finder findByText(String text) => find.text(text);

/// Helper to tap a widget and settle
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
''';
  }

  static String generateBlocTestExample(ProjectConfig config) {
    return '''import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:${config.appNameSnakeCase}/core/base/base_state.dart';
import 'package:${config.appNameSnakeCase}/features/home/bloc/home_bloc.dart';
import 'package:${config.appNameSnakeCase}/features/home/bloc/home_event.dart';
import 'package:${config.appNameSnakeCase}/features/home/bloc/home_state.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late MockGetHomeDataUseCase mockGetHomeData;
  late HomeBloc bloc;

  setUp(() {
    mockGetHomeData = MockGetHomeDataUseCase();
    bloc = HomeBloc(mockGetHomeData);
  });

  tearDown(() => bloc.close());

  group('HomeBloc', () {
    test('initial state is correct', () {
      expect(bloc.state, const HomeState());
      expect(bloc.state.status, StateStatus.initial);
      expect(bloc.state.data, isNull);
    });

    blocTest<HomeBloc, HomeState>(
      'emits [loading, success] when data is fetched successfully',
      build: () {
        when(() => mockGetHomeData()).thenAnswer(
          (_) async => testHomeModel,
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const HomeLoadRequested()),
      expect: () => [
        const HomeState(status: StateStatus.loading),
        isA<HomeState>()
            .having((s) => s.status, 'status', StateStatus.success)
            .having((s) => s.data, 'data', isNotNull),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'emits [loading, error] when fetching fails',
      build: () {
        when(() => mockGetHomeData()).thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (bloc) => bloc.add(const HomeLoadRequested()),
      expect: () => [
        const HomeState(status: StateStatus.loading),
        isA<HomeState>()
            .having((s) => s.status, 'status', StateStatus.error)
            .having(
                (s) => s.errorMessage, 'errorMessage', contains('Network error')),
      ],
    );
  });
}
''';
  }

  static String generateWidgetTestExampleMvi(ProjectConfig config) {
    return '''import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:${config.appNameSnakeCase}/core/base/base_state.dart';
import 'package:${config.appNameSnakeCase}/features/home/bloc/home_bloc.dart';
import 'package:${config.appNameSnakeCase}/features/home/bloc/home_event.dart';
import 'package:${config.appNameSnakeCase}/features/home/bloc/home_state.dart';
import '../../helpers/test_helpers.dart';

class MockHomeBloc extends MockBloc<HomeEvent, HomeState>
    implements HomeBloc {}

void main() {
  late MockHomeBloc mockBloc;

  setUp(() {
    mockBloc = MockHomeBloc();
  });

  group('HomeView', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const HomeState(status: StateStatus.loading),
      );

      await tester.pumpWidget(
        createTestableWidget(
          BlocProvider<HomeBloc>.value(
            value: mockBloc,
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                switch (state.status) {
                  case StateStatus.initial:
                  case StateStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case StateStatus.error:
                    return Center(child: Text(state.errorMessage ?? 'Error'));
                  case StateStatus.success:
                    return const Center(child: Text('Home screen'));
                }
              },
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows content on success', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const HomeState(status: StateStatus.success),
      );

      await tester.pumpWidget(
        createTestableWidget(
          BlocProvider<HomeBloc>.value(
            value: mockBloc,
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                switch (state.status) {
                  case StateStatus.initial:
                  case StateStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case StateStatus.error:
                    return Center(child: Text(state.errorMessage ?? 'Error'));
                  case StateStatus.success:
                    return const Center(child: Text('Home screen'));
                }
              },
            ),
          ),
        ),
      );

      expect(find.text('Home screen'), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const HomeState(
          status: StateStatus.error,
          errorMessage: 'Something went wrong',
        ),
      );

      await tester.pumpWidget(
        createTestableWidget(
          BlocProvider<HomeBloc>.value(
            value: mockBloc,
            child: BlocBuilder<HomeBloc, HomeState>(
              builder: (context, state) {
                switch (state.status) {
                  case StateStatus.initial:
                  case StateStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case StateStatus.error:
                    return Center(child: Text(state.errorMessage ?? 'Error'));
                  case StateStatus.success:
                    return const Center(child: Text('Home screen'));
                }
              },
            ),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });
}
''';
  }

  static String generateUnitTestExample(ProjectConfig config) {
    return '''import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:${config.appNameSnakeCase}/core/base/base_viewmodel.dart';
import 'package:${config.appNameSnakeCase}/features/home/models/home_model.dart';
import 'package:${config.appNameSnakeCase}/features/home/viewmodels/home_viewmodel.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late MockGetHomeDataUseCase mockGetHomeData;
  late HomeViewModel viewModel;

  setUp(() {
    mockGetHomeData = MockGetHomeDataUseCase();
    viewModel = HomeViewModel(mockGetHomeData);
  });

  group('HomeViewModel', () {
    test('initial state is initial', () {
      expect(viewModel.state, ViewState.initial);
      expect(viewModel.isBusy, isFalse);
      expect(viewModel.data, isNull);
    });

    test('initial state has no error', () {
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.hasError, isFalse);
    });

    test('loadData sets success state with data', () async {
      when(() => mockGetHomeData()).thenAnswer(
        (_) async => testHomeModel,
      );

      await viewModel.loadData();

      expect(viewModel.state, ViewState.success);
      expect(viewModel.data, testHomeModel);
      expect(viewModel.isBusy, isFalse);
    });

    test('loadData sets error state on failure', () async {
      when(() => mockGetHomeData()).thenThrow(
        Exception('Network error'),
      );

      await viewModel.loadData();

      expect(viewModel.state, ViewState.error);
      expect(viewModel.hasError, isTrue);
      expect(viewModel.errorMessage, contains('Network error'));
      expect(viewModel.data, isNull);
    });
  });
}
''';
  }

  static String generateWidgetTestExample(ProjectConfig config) {
    return '''import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:${config.appNameSnakeCase}/core/base/base_viewmodel.dart';
import 'package:${config.appNameSnakeCase}/features/home/models/home_model.dart';
import 'package:${config.appNameSnakeCase}/features/home/viewmodels/home_viewmodel.dart';
import '../../helpers/test_helpers.dart';

/// Creates a HomeView-like widget driven by the given [viewModel],
/// bypassing HomeView's internal ChangeNotifierProvider.
Widget createHomeTestWidget(HomeViewModel viewModel) {
  return createTestableWidget(
    ChangeNotifierProvider<HomeViewModel>.value(
      value: viewModel,
      child: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('Home')),
            body: const _HomeBody(),
          );
        },
      ),
    ),
  );
}

void main() {
  late MockGetHomeDataUseCase mockGetHomeData;
  late HomeViewModel viewModel;

  setUp(() {
    mockGetHomeData = MockGetHomeDataUseCase();
    viewModel = HomeViewModel(mockGetHomeData);
  });

  group('HomeView', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      // Stub that never completes so the ViewModel stays in loading state
      when(() => mockGetHomeData()).thenAnswer(
        (_) => Completer<HomeModel>().future,
      );

      viewModel.loadData();
      await tester.pumpWidget(createHomeTestWidget(viewModel));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows data on success', (tester) async {
      when(() => mockGetHomeData()).thenAnswer(
        (_) async => testHomeModel,
      );

      await viewModel.loadData();
      await tester.pumpWidget(createHomeTestWidget(viewModel));

      expect(find.text('Home screen'), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      when(() => mockGetHomeData()).thenThrow(
        Exception('Something went wrong'),
      );

      await viewModel.loadData();
      await tester.pumpWidget(createHomeTestWidget(viewModel));

      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });
  });
}

/// Mirrors the body-building logic of HomeView for testing purposes.
class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeViewModel>();
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
          child: Text('Home screen'),
        );
    }
  }
}
''';
  }

  static String generateTestHelpersRiverpod(ProjectConfig config) {
    return '''import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:${config.appNameSnakeCase}/domain/repositories/home_repository.dart';
import 'package:${config.appNameSnakeCase}/domain/usecases/get_home_data_usecase.dart';
import 'package:${config.appNameSnakeCase}/features/home/models/home_model.dart';

// --- Mocks ---

class MockHomeRepository extends Mock implements HomeRepository {}

class MockGetHomeDataUseCase extends Mock implements GetHomeDataUseCase {}

// --- Test data ---

const testHomeModel = HomeModel();

// --- Widget helpers ---

/// Wraps a widget with MaterialApp for testing
Widget createTestableWidget(Widget child) {
  return MaterialApp(
    home: child,
  );
}

/// Pumps a widget and waits for animations to settle
Future<void> pumpAndSettle(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(createTestableWidget(widget));
  await tester.pumpAndSettle();
}

/// Helper to find widgets by type
Finder findByType<T>() => find.byType(T);

/// Helper to find widgets by text
Finder findByText(String text) => find.text(text);

/// Helper to tap a widget and settle
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
''';
  }

  static String generateNotifierTestExample(ProjectConfig config) {
    return '''import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:${config.appNameSnakeCase}/domain/usecases/get_home_data_usecase.dart';
import 'package:${config.appNameSnakeCase}/features/home/models/home_model.dart';
import 'package:${config.appNameSnakeCase}/features/home/providers/home_providers.dart';
import '../../helpers/test_helpers.dart';

void main() {
  late MockGetHomeDataUseCase mockGetHomeData;

  setUp(() {
    mockGetHomeData = MockGetHomeDataUseCase();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        getHomeDataUseCaseProvider.overrideWithValue(mockGetHomeData),
      ],
    );
  }

  group('HomeNotifier', () {
    test('emits loading then data on success', () async {
      when(() => mockGetHomeData()).thenAnswer(
        (_) async => testHomeModel,
      );

      final container = createContainer();
      addTearDown(container.dispose);

      final subscription = container.listen(
        homeNotifierProvider,
        (_, __) {},
      );

      // Initially loading
      expect(
        container.read(homeNotifierProvider),
        isA<AsyncLoading<HomeModel>>(),
      );

      // Wait for build to complete
      await container.read(homeNotifierProvider.future);

      expect(
        container.read(homeNotifierProvider).value,
        isA<HomeModel>(),
      );

      subscription.close();
    });

    test('emits loading then error on failure', () async {
      when(() => mockGetHomeData()).thenThrow(Exception('Network error'));

      final container = createContainer();
      addTearDown(container.dispose);

      final subscription = container.listen(
        homeNotifierProvider,
        (_, __) {},
      );

      // Wait for build to complete (with error)
      try {
        await container.read(homeNotifierProvider.future);
      } catch (_) {}

      expect(
        container.read(homeNotifierProvider),
        isA<AsyncError<HomeModel>>(),
      );

      subscription.close();
    });
  });
}
''';
  }

  static String generateWidgetTestExampleRiverpod(ProjectConfig config) {
    return '''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:${config.appNameSnakeCase}/features/home/models/home_model.dart';
import 'package:${config.appNameSnakeCase}/features/home/notifiers/home_notifier.dart';
import 'package:${config.appNameSnakeCase}/features/home/providers/home_providers.dart';
import 'package:${config.appNameSnakeCase}/features/home/views/home_view.dart';

void main() {
  group('HomeView', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeNotifierProvider.overrideWith(
              () => _LoadingNotifier(),
            ),
          ],
          child: const MaterialApp(home: HomeView()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows content on success', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeNotifierProvider.overrideWith(
              () => _SuccessNotifier(),
            ),
          ],
          child: const MaterialApp(home: HomeView()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Home screen'), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeNotifierProvider.overrideWith(
              () => _ErrorNotifier(),
            ),
          ],
          child: const MaterialApp(home: HomeView()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });
  });
}

class _LoadingNotifier extends HomeNotifier {
  @override
  Future<HomeModel> build() async {
    await Future.delayed(const Duration(days: 1));
    return const HomeModel();
  }
}

class _SuccessNotifier extends HomeNotifier {
  @override
  Future<HomeModel> build() async {
    return const HomeModel();
  }
}

class _ErrorNotifier extends HomeNotifier {
  @override
  Future<HomeModel> build() async {
    throw Exception('Something went wrong');
  }
}
''';
  }
}
