import 'package:flutterforge/src/config/project_config.dart';

class RouterTemplate {
  RouterTemplate._();

  static String generate(ProjectConfig config) {
    final hasStartup = config.hasModule('startup');
    final initialLocation = hasStartup ? '/startup' : '/';

    final startupImport = hasStartup
        ? "import 'package:${config.appNameSnakeCase}/app/startup/startup_view.dart';\n"
        : '';

    final startupRoute = hasStartup
        ? '''
      GoRoute(
        path: '/startup',
        name: 'startup',
        builder: (context, state) => StartupView(
          onReady: () => router.go('/'),
        ),
      ),'''
        : '';

    return '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:${config.appNameSnakeCase}/features/home/views/home_view.dart';
$startupImport
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '$initialLocation',
    routes: [$startupRoute
      GoRoute(
        path: '/',
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
