import 'package:flutterforge/src/config/project_config.dart';

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
}
