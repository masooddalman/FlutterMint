import 'package:flutterforge/src/config/project_config.dart';

class TestHelpersTemplate {
  TestHelpersTemplate._();

  static String generateTestHelpers(ProjectConfig config) {
    return '''import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

import 'package:${config.appNameSnakeCase}/data/repositories/home_repository.dart';
import 'package:${config.appNameSnakeCase}/domain/usecases/get_home_data_usecase.dart';
import 'package:${config.appNameSnakeCase}/features/home/viewmodels/home_viewmodel.dart';

void main() {
  group('HomeViewModel', () {
    late HomeViewModel viewModel;

    setUp(() {
      viewModel = HomeViewModel(GetHomeDataUseCase(HomeRepositoryImpl()));
    });

    test('initial state is not busy', () {
      expect(viewModel.isBusy, isFalse);
    });

    test('initial state has no error', () {
      expect(viewModel.errorMessage, isNull);
    });

    test('initial state has no data', () {
      expect(viewModel.homeData, isNull);
    });

    test('loadData sets data after completion', () async {
      await viewModel.loadData();

      expect(viewModel.homeData, isNotNull);
      expect(viewModel.homeData!.title, contains('Welcome'));
      expect(viewModel.isBusy, isFalse);
    });
  });
}
''';
  }

  static String generateWidgetTestExample(ProjectConfig config) {
    return '''import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:${config.appNameSnakeCase}/features/home/views/home_view.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('HomeView', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(createTestableWidget(const HomeView()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows content after loading', (tester) async {
      await tester.pumpWidget(createTestableWidget(const HomeView()));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });
  });
}
''';
  }
}
