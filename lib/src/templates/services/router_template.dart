import 'package:fluttermint/src/config/project_config.dart';

class RouterTemplate {
  RouterTemplate._();

  static String generate(ProjectConfig config) {
    final hasStartup = config.hasModule('startup');

    final startupImport = hasStartup
        ? "import 'package:${config.appNameSnakeCase}/app/startup/startup_view.dart';\n"
        : '';

    final startupPath = hasStartup
        ? "  static const startup = '/startup';\n"
        : '';

    final startupRoute = hasStartup
        ? '''
      GoRoute(
        path: RoutePaths.startup,
        name: 'startup',
        builder: (context, state) => StartupView(
          onReady: () => router.go(RoutePaths.home),
        ),
      ),'''
        : '';

    return '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:${config.appNameSnakeCase}/features/home/views/home_view.dart';
$startupImport
class RoutePaths {
  RoutePaths._();

  static const home = '/';
$startupPath  // Add more paths here
}

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: RoutePaths.${hasStartup ? 'startup' : 'home'},
    routes: [$startupRoute
      GoRoute(
        path: RoutePaths.home,
        name: 'home',
        builder: (context, state) => const HomeView(),
      ),
      // Add more routes here
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: \${state.uri}'),
      ),
    ),
  );
}
''';
  }
}
