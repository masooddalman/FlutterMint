import 'package:flutterforge/src/config/project_config.dart';

class RouterTemplate {
  RouterTemplate._();

  static String generate(ProjectConfig config) {
    return '''import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:${config.appNameSnakeCase}/features/home/views/home_view.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
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
