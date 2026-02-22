import 'package:flutterforge/src/config/project_config.dart';

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

    final importBlock = imports.isNotEmpty
        ? imports.map((i) => "import '$i';").join('\n')
        : '';

    final materialApp = hasRouting
        ? _routerMaterialApp(config, hasTheming, hasLocalization)
        : _simpleMaterialApp(config, hasTheming, hasLocalization, hasStartupFlow);

    final body = hasProviders
        ? _wrapWithMultiProvider(materialApp, providerDeclarations)
        : materialApp;

    final providerImport = hasProviders
        ? "import 'package:provider/provider.dart';\n"
        : '';

    if (hasStartupFlow) {
      return '''import 'package:flutter/material.dart';
$providerImport${importBlock.isNotEmpty ? '$importBlock\n' : ''}
class ${config.appNamePascalCase}App extends StatefulWidget {
  const ${config.appNamePascalCase}App({super.key});

  @override
  State<${config.appNamePascalCase}App> createState() => _${config.appNamePascalCase}AppState();
}

class _${config.appNamePascalCase}AppState extends State<${config.appNamePascalCase}App> {
  bool _ready = false;

  @override
  Widget build(BuildContext context) {
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
  ) {
    final hasToast = config.hasModule('toast');
    final toastLine = hasToast
        ? '\n      scaffoldMessengerKey: ToastService.messengerKey,'
        : '';
    final themeLines = hasTheming
        ? '''
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: context.watch<ThemeProvider>().themeMode,'''
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
  ) {
    final hasToast = config.hasModule('toast');
    final toastLine = hasToast
        ? '\n      scaffoldMessengerKey: ToastService.messengerKey,'
        : '';
    final themeLines = hasTheming
        ? '''
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: context.watch<ThemeProvider>().themeMode,'''
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
