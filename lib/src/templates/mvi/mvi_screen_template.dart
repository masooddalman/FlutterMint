import 'package:fluttermint/src/config/project_config.dart';
import 'package:fluttermint/src/templates/mvvm/screen_template.dart';

class MviScreenTemplate {
  MviScreenTemplate._();

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

  // --- MVI-specific templates ---

  static String generateEvent(String name, ProjectConfig config) {
    final pascal = ProjectConfig.toPascalCase(name);

    return '''import 'package:${config.appNameSnakeCase}/core/base/base_event.dart';

sealed class ${pascal}Event extends BaseEvent {
  const ${pascal}Event();
}

final class ${pascal}LoadRequested extends ${pascal}Event {
  const ${pascal}LoadRequested();
}
''';
  }

  static String generateState(String name, ProjectConfig config) {
    final pascal = ProjectConfig.toPascalCase(name);

    return '''import 'package:equatable/equatable.dart';

import 'package:${config.appNameSnakeCase}/core/base/base_state.dart';
import 'package:${config.appNameSnakeCase}/features/$name/models/${name}_model.dart';

final class ${pascal}State extends Equatable {
  const ${pascal}State({
    this.status = StateStatus.initial,
    this.data,
    this.errorMessage,
  });

  final StateStatus status;
  final ${pascal}Model? data;
  final String? errorMessage;

  ${pascal}State copyWith({
    StateStatus? status,
    ${pascal}Model? data,
    String? errorMessage,
  }) {
    return ${pascal}State(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, data, errorMessage];
}
''';
  }

  static String generateBloc(String name, ProjectConfig config) {
    final pascal = ProjectConfig.toPascalCase(name);
    final loggerImport = config.hasModule('logging')
        ? "import 'package:${config.appNameSnakeCase}/core/services/logger_service.dart';\n"
        : '';
    final loggerCall = config.hasModule('logging')
        ? "\n      LoggerService.info('$pascal data loaded');"
        : '';

    return '''import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:${config.appNameSnakeCase}/core/base/base_state.dart';
import 'package:${config.appNameSnakeCase}/domain/usecases/get_${name}_data_usecase.dart';
import 'package:${config.appNameSnakeCase}/features/$name/bloc/${name}_event.dart';
import 'package:${config.appNameSnakeCase}/features/$name/bloc/${name}_state.dart';
$loggerImport
class ${pascal}Bloc extends Bloc<${pascal}Event, ${pascal}State> {
  ${pascal}Bloc(this._getData) : super(const ${pascal}State()) {
    on<${pascal}LoadRequested>(_onLoadRequested);
  }

  final Get${pascal}DataUseCase _getData;

  Future<void> _onLoadRequested(
    ${pascal}LoadRequested event,
    Emitter<${pascal}State> emit,
  ) async {
    emit(state.copyWith(status: StateStatus.loading));
    try {
      final data = await _getData();$loggerCall
      emit(state.copyWith(status: StateStatus.success, data: data));
    } catch (e) {
      emit(state.copyWith(
        status: StateStatus.error,
        errorMessage: e.toString(),
      ));
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

    final createBloc = hasLocator
        ? 'locator<${pascal}Bloc>()..add(const ${pascal}LoadRequested())'
        : '${pascal}Bloc(Get${pascal}DataUseCase(${pascal}RepositoryImpl()))..add(const ${pascal}LoadRequested())';

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
    final fieldsBlock =
        hasParams ? '$fieldDeclarations\n\n$constructor' : constructor;

    return '''import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:${config.appNameSnakeCase}/core/base/base_state.dart';
import 'package:${config.appNameSnakeCase}/features/$name/bloc/${name}_bloc.dart';
import 'package:${config.appNameSnakeCase}/features/$name/bloc/${name}_event.dart';
import 'package:${config.appNameSnakeCase}/features/$name/bloc/${name}_state.dart';
import 'package:${config.appNameSnakeCase}/features/$name/models/${name}_model.dart';
$locatorImport$nonLocatorImports
class ${pascal}View extends StatelessWidget {
$fieldsBlock

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => $createBloc,
      child: Scaffold(
        appBar: AppBar(
          title: ${constPrefix}Text('$title'),
        ),
        // Use BlocSelector to rebuild only the widgets that depend on
        // specific state slices. Each section selects its own data,
        // preventing unnecessary rebuilds of unrelated parts.
        body: BlocSelector<${pascal}Bloc, ${pascal}State, StateStatus>(
          selector: (state) => state.status,
          builder: (context, status) {
            switch (status) {
              case StateStatus.initial:
              case StateStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case StateStatus.error:
                return BlocSelector<${pascal}Bloc, ${pascal}State, String?>(
                  selector: (state) => state.errorMessage,
                  builder: (context, errorMessage) {
                    return Center(
                      child: Text(
                        errorMessage ?? 'An error occurred',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  },
                );
              case StateStatus.success:
                return BlocSelector<${pascal}Bloc, ${pascal}State, ${pascal}Model?>(
                  selector: (state) => state.data,
                  builder: (context, data) {
                    return const Center(
                      child: Text('$title screen'),
                    );
                  },
                );
            }
          },
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

    return '''import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:$pkg/core/base/base_state.dart';
import 'package:$pkg/domain/usecases/get_${name}_data_usecase.dart';
import 'package:$pkg/features/$name/bloc/${name}_bloc.dart';
import 'package:$pkg/features/$name/bloc/${name}_event.dart';
import 'package:$pkg/features/$name/bloc/${name}_state.dart';
import 'package:$pkg/features/$name/models/${name}_model.dart';

class MockGet${pascal}DataUseCase extends Mock implements Get${pascal}DataUseCase {}

void main() {
  late MockGet${pascal}DataUseCase mockUseCase;
  late ${pascal}Bloc bloc;

  setUp(() {
    mockUseCase = MockGet${pascal}DataUseCase();
    bloc = ${pascal}Bloc(mockUseCase);
  });

  tearDown(() => bloc.close());

  group('${pascal}Bloc', () {
    test('initial state is correct', () {
      expect(bloc.state, const ${pascal}State());
      expect(bloc.state.status, StateStatus.initial);
      expect(bloc.state.data, isNull);
    });

    blocTest<${pascal}Bloc, ${pascal}State>(
      'emits [loading, success] when data is fetched successfully',
      build: () {
        when(() => mockUseCase()).thenAnswer(
          (_) async => const ${pascal}Model(),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const ${pascal}LoadRequested()),
      expect: () => [
        const ${pascal}State(status: StateStatus.loading),
        isA<${pascal}State>()
            .having((s) => s.status, 'status', StateStatus.success)
            .having((s) => s.data, 'data', isNotNull),
      ],
    );

    blocTest<${pascal}Bloc, ${pascal}State>(
      'emits [loading, error] when fetching fails',
      build: () {
        when(() => mockUseCase()).thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (bloc) => bloc.add(const ${pascal}LoadRequested()),
      expect: () => [
        const ${pascal}State(status: StateStatus.loading),
        isA<${pascal}State>()
            .having((s) => s.status, 'status', StateStatus.error)
            .having(
                (s) => s.errorMessage, 'errorMessage', contains('Network error')),
      ],
    );
  });
}
''';
  }

  static String generateWidgetTest(String name, ProjectConfig config) {
    final pascal = ProjectConfig.toPascalCase(name);
    final pkg = config.appNameSnakeCase;
    final title = _toTitleCase(name);

    return '''import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:$pkg/core/base/base_state.dart';
import 'package:$pkg/features/$name/bloc/${name}_bloc.dart';
import 'package:$pkg/features/$name/bloc/${name}_event.dart';
import 'package:$pkg/features/$name/bloc/${name}_state.dart';

class Mock${pascal}Bloc extends MockBloc<${pascal}Event, ${pascal}State>
    implements ${pascal}Bloc {}

Widget _createTestWidget(${pascal}Bloc bloc) {
  return MaterialApp(
    home: BlocProvider<${pascal}Bloc>.value(
      value: bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('$title')),
        body: BlocSelector<${pascal}Bloc, ${pascal}State, StateStatus>(
          selector: (state) => state.status,
          builder: (context, status) {
            switch (status) {
              case StateStatus.initial:
              case StateStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case StateStatus.error:
                return BlocSelector<${pascal}Bloc, ${pascal}State, String?>(
                  selector: (state) => state.errorMessage,
                  builder: (context, errorMessage) {
                    return Center(
                      child: Text(
                        errorMessage ?? 'An error occurred',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  },
                );
              case StateStatus.success:
                return const Center(child: Text('$title screen'));
            }
          },
        ),
      ),
    ),
  );
}

void main() {
  late Mock${pascal}Bloc mockBloc;

  setUp(() {
    mockBloc = Mock${pascal}Bloc();
  });

  group('${pascal}View', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const ${pascal}State(status: StateStatus.loading),
      );

      await tester.pumpWidget(_createTestWidget(mockBloc));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows content on success', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const ${pascal}State(status: StateStatus.success),
      );

      await tester.pumpWidget(_createTestWidget(mockBloc));

      expect(find.text('$title screen'), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      when(() => mockBloc.state).thenReturn(
        const ${pascal}State(
          status: StateStatus.error,
          errorMessage: 'Something went wrong',
        ),
      );

      await tester.pumpWidget(_createTestWidget(mockBloc));

      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });
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
