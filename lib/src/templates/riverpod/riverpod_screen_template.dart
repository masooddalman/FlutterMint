import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/templates/mvvm/screen_template.dart';

class RiverpodScreenTemplate {
  RiverpodScreenTemplate._();

  // Domain layer is pattern-agnostic — reuse from ScreenTemplate.

  static String generateModel(String name, ProjectConfig config) =>
      ScreenTemplate.generateModel(name, config);

  static String generateRepository(String name, ProjectConfig config) =>
      ScreenTemplate.generateRepository(name, config);

  static String generateRepositoryImpl(String name, ProjectConfig config) =>
      ScreenTemplate.generateRepositoryImpl(name, config);

  static String generateUseCase(String name, ProjectConfig config) =>
      ScreenTemplate.generateUseCase(name, config);

  static String generateSharedWidgetsPlaceholder() =>
      ScreenTemplate.generateSharedWidgetsPlaceholder();

  // --- Riverpod-specific templates ---

  static String generateProviders(String name, ProjectConfig config) {
    final pascal = ProjectConfig.toPascalCase(name);
    final pkg = config.appNameSnakeCase;

    return '''import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:$pkg/data/repositories/${name}_repository.dart';
import 'package:$pkg/domain/repositories/${name}_repository.dart';
import 'package:$pkg/domain/usecases/get_${name}_data_usecase.dart';
import 'package:$pkg/features/$name/models/${name}_model.dart';
import 'package:$pkg/features/$name/notifiers/${name}_notifier.dart';

final ${name}RepositoryProvider = Provider<${pascal}Repository>((ref) {
  return ${pascal}RepositoryImpl();
});

final get${pascal}DataUseCaseProvider = Provider<Get${pascal}DataUseCase>((ref) {
  return Get${pascal}DataUseCase(ref.watch(${name}RepositoryProvider));
});

final ${name}NotifierProvider =
    AsyncNotifierProvider<${pascal}Notifier, ${pascal}Model>(
  ${pascal}Notifier.new,
);
''';
  }

  static String generateNotifier(String name, ProjectConfig config) {
    final pascal = ProjectConfig.toPascalCase(name);
    final pkg = config.appNameSnakeCase;
    final loggerImport = config.hasModule('logging')
        ? "import 'package:$pkg/core/services/logger_service.dart';\n"
        : '';
    final loggerCall = config.hasModule('logging')
        ? "\n    LoggerService.info('$pascal data loaded');"
        : '';

    return '''import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:$pkg/features/$name/models/${name}_model.dart';
import 'package:$pkg/features/$name/providers/${name}_providers.dart';
$loggerImport
class ${pascal}Notifier extends AsyncNotifier<${pascal}Model> {
  @override
  Future<${pascal}Model> build() async {
    final useCase = ref.watch(get${pascal}DataUseCaseProvider);
    final data = await useCase();$loggerCall
    return data;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.watch(get${pascal}DataUseCaseProvider);
      return useCase();
    });
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
    final title = _toTitleCase(name);
    final patternDesc = config.designPattern.description;

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
    final fieldsBlock =
        hasParams ? '$fieldDeclarations\n\n$constructor' : constructor;

    return '''import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:${config.appNameSnakeCase}/features/$name/providers/${name}_providers.dart';

class ${pascal}View extends ConsumerWidget {
$fieldsBlock

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(${name}NotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: ${constPrefix}Text('$title'),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            error.toString(),
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (data) => const Center(
          child: Text('$title screen\\n$patternDesc', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
''';
  }

  static String generateUnitTest(String name, ProjectConfig config) {
    final pascal = ProjectConfig.toPascalCase(name);
    final pkg = config.appNameSnakeCase;

    return '''import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:$pkg/domain/usecases/get_${name}_data_usecase.dart';
import 'package:$pkg/features/$name/models/${name}_model.dart';
import 'package:$pkg/features/$name/notifiers/${name}_notifier.dart';
import 'package:$pkg/features/$name/providers/${name}_providers.dart';

class MockGet${pascal}DataUseCase extends Mock
    implements Get${pascal}DataUseCase {}

void main() {
  late MockGet${pascal}DataUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockGet${pascal}DataUseCase();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        get${pascal}DataUseCaseProvider.overrideWithValue(mockUseCase),
      ],
    );
  }

  group('${pascal}Notifier', () {
    test('emits loading then data on success', () async {
      when(() => mockUseCase()).thenAnswer(
        (_) async => const ${pascal}Model(),
      );

      final container = createContainer();
      addTearDown(container.dispose);

      // Trigger the notifier build
      final subscription = container.listen(
        ${name}NotifierProvider,
        (_, __) {},
      );

      // Initially loading
      expect(
        container.read(${name}NotifierProvider),
        isA<AsyncLoading<${pascal}Model>>(),
      );

      // Wait for build to complete
      await container.read(${name}NotifierProvider.future);

      expect(
        container.read(${name}NotifierProvider).value,
        isA<${pascal}Model>(),
      );

      subscription.close();
    });

    test('emits loading then error on failure', () async {
      when(() => mockUseCase()).thenThrow(Exception('Network error'));

      final container = createContainer();
      addTearDown(container.dispose);

      final subscription = container.listen(
        ${name}NotifierProvider,
        (_, __) {},
      );

      // Wait for build to complete (with error)
      try {
        await container.read(${name}NotifierProvider.future);
      } catch (_) {}

      expect(
        container.read(${name}NotifierProvider),
        isA<AsyncError<${pascal}Model>>(),
      );

      subscription.close();
    });
  });
}
''';
  }

  static String generateWidgetTest(String name, ProjectConfig config) {
    final pascal = ProjectConfig.toPascalCase(name);
    final pkg = config.appNameSnakeCase;
    final title = _toTitleCase(name);
    final patternDesc = config.designPattern.description;

    return '''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:$pkg/features/$name/models/${name}_model.dart';
import 'package:$pkg/features/$name/providers/${name}_providers.dart';
import 'package:$pkg/features/$name/views/${name}_view.dart';

void main() {
  group('${pascal}View', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ${name}NotifierProvider.overrideWith(
              () => _LoadingNotifier(),
            ),
          ],
          child: const MaterialApp(home: ${pascal}View()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows content on success', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ${name}NotifierProvider.overrideWith(
              () => _SuccessNotifier(),
            ),
          ],
          child: const MaterialApp(home: ${pascal}View()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('$title screen\\n$patternDesc'), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ${name}NotifierProvider.overrideWith(
              () => _ErrorNotifier(),
            ),
          ],
          child: const MaterialApp(home: ${pascal}View()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });
  });
}

class _LoadingNotifier extends ${pascal}Notifier {
  @override
  Future<${pascal}Model> build() async {
    await Future.delayed(const Duration(days: 1));
    return const ${pascal}Model();
  }
}

class _SuccessNotifier extends ${pascal}Notifier {
  @override
  Future<${pascal}Model> build() async {
    return const ${pascal}Model();
  }
}

class _ErrorNotifier extends ${pascal}Notifier {
  @override
  Future<${pascal}Model> build() async {
    throw Exception('Something went wrong');
  }
}
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
