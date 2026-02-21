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

    final importBlock = imports.isNotEmpty
        ? imports.map((i) => "import '$i';").join('\n')
        : '';

    final materialApp = hasRouting
        ? _routerMaterialApp(config, hasTheming, hasLocalization)
        : _simpleMaterialApp(config, hasTheming, hasLocalization);

    final body = hasProviders
        ? _wrapWithMultiProvider(materialApp, providerDeclarations)
        : materialApp;

    final providerImport = hasProviders
        ? "import 'package:provider/provider.dart';\n"
        : '';

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
      debugShowCheckedModeBanner: false,$themeLines$localizationLines
      routerConfig: AppRouter.router,
    )''';
  }

  static String _simpleMaterialApp(
    ProjectConfig config,
    bool hasTheming,
    bool hasLocalization,
  ) {
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

    return '''MaterialApp(
      title: '${config.appNamePascalCase}',
      debugShowCheckedModeBanner: false,$themeLines$localizationLines
      home: const HomeView(),
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
