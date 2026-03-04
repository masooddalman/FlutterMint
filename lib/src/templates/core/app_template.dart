import 'package:fluttermint/src/config/design_pattern.dart';
import 'package:fluttermint/src/config/project_config.dart';

class AppTemplate {
  AppTemplate._();

  static String generate({
    required ProjectConfig config,
    required List<String> imports,
    required List<String> providerDeclarations,
  }) {
    final hasRouting = config.hasModule('routing');
    final hasTheming = config.hasModule('theming');
    final hasLocalization = config.hasModule('localization');
    final hasProviders = providerDeclarations.isNotEmpty;
    final hasStartupFlow = config.hasModule('startup') && !hasRouting;
    final isRiverpod = config.designPattern == DesignPattern.riverpod;

    final importBlock = imports.isNotEmpty
        ? imports.map((i) => "import '$i';").join('\n')
        : '';

    final materialApp = hasRouting
        ? _routerMaterialApp(config, hasTheming, hasLocalization, isRiverpod)
        : _simpleMaterialApp(
            config, hasTheming, hasLocalization, hasStartupFlow, isRiverpod);

    final body = hasProviders
        ? _wrapWithMultiProvider(materialApp, providerDeclarations)
        : materialApp;

    final providerImport = hasProviders
        ? "import 'package:provider/provider.dart';\n"
        : '';

    // Riverpod needs flutter_riverpod import in app.dart when theming is
    // enabled (ConsumerWidget + ref.watch for theme).
    final riverpodImport = isRiverpod && hasTheming
        ? "import 'package:flutter_riverpod/flutter_riverpod.dart';\n"
        : '';

    if (hasStartupFlow) {
      final superClass =
          isRiverpod && hasTheming ? 'ConsumerStatefulWidget' : 'StatefulWidget';
      final stateClass = isRiverpod && hasTheming
          ? 'ConsumerState<${config.appNamePascalCase}App>'
          : 'State<${config.appNamePascalCase}App>';

      return '''import 'package:flutter/material.dart';
$providerImport$riverpodImport${importBlock.isNotEmpty ? '$importBlock\n' : ''}
class ${config.appNamePascalCase}App extends $superClass {
  const ${config.appNamePascalCase}App({super.key});

  @override
  $stateClass createState() => _${config.appNamePascalCase}AppState();
}

class _${config.appNamePascalCase}AppState extends $stateClass {
  bool _ready = false;

  @override
  Widget build(BuildContext context) {
    return $body;
  }
}
''';
    }

    if (isRiverpod && hasTheming) {
      return '''import 'package:flutter/material.dart';
$riverpodImport${importBlock.isNotEmpty ? '$importBlock\n' : ''}
class ${config.appNamePascalCase}App extends ConsumerWidget {
  const ${config.appNamePascalCase}App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return $body;
  }
}
''';
    }

    return '''import 'package:flutter/material.dart';
$providerImport${importBlock.isNotEmpty ? '$importBlock\n' : ''}
class ${config.appNamePascalCase}App extends StatelessWidget {
  const ${config.appNamePascalCase}App({super.key});

  @override
  Widget build(BuildContext context) {
    return $body;
  }
}
''';
  }

  static String _routerMaterialApp(
    ProjectConfig config,
    bool hasTheming,
    bool hasLocalization,
    bool isRiverpod,
  ) {
    final hasToast = config.hasModule('toast');
    final toastLine = hasToast
        ? '\n      scaffoldMessengerKey: ToastService.messengerKey,'
        : '';
    final themeLines = hasTheming
        ? (isRiverpod
            ? '''
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeNotifierProvider),'''
            : '''
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: context.watch<ThemeProvider>().themeMode,''')
        : '''
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),''';

    final localizationLines = hasLocalization
        ? '''
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,'''
        : '';

    return '''MaterialApp.router(
      title: '${config.appNamePascalCase}',
      debugShowCheckedModeBanner: false,$toastLine$themeLines$localizationLines
      routerConfig: AppRouter.router,
    )''';
  }

  static String _simpleMaterialApp(
    ProjectConfig config,
    bool hasTheming,
    bool hasLocalization,
    bool hasStartup,
    bool isRiverpod,
  ) {
    final hasToast = config.hasModule('toast');
    final toastLine = hasToast
        ? '\n      scaffoldMessengerKey: ToastService.messengerKey,'
        : '';
    final themeLines = hasTheming
        ? (isRiverpod
            ? '''
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeNotifierProvider),'''
            : '''
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: context.watch<ThemeProvider>().themeMode,''')
        : '''
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),''';

    final localizationLines = hasLocalization
        ? '''
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,'''
        : '';

    final homeLine = hasStartup
        ? '''
      home: _ready
          ? const HomeView()
          : StartupView(onReady: () => setState(() => _ready = true)),'''
        : '''
      home: const HomeView(),''';

    return '''MaterialApp(
      title: '${config.appNamePascalCase}',
      debugShowCheckedModeBanner: false,$toastLine$themeLines$localizationLines$homeLine
    )''';
  }

  static String _wrapWithMultiProvider(
    String child,
    List<String> providers,
  ) {
    final providerLines = providers.map((p) => '        $p').join('\n');
    return '''MultiProvider(
      providers: [
$providerLines
      ],
      child: Builder(
        builder: (context) {
          return $child;
        },
      ),
    )''';
  }
}
