import 'package:flutterforge/src/config/project_config.dart';
import 'package:flutterforge/src/modules/module.dart';
import 'package:flutterforge/src/templates/services/api_client_template.dart';

class ApiModule extends Module {
  @override
  String get id => 'api';

  @override
  String get displayName => 'API Requests & Interceptors (Dio)';

  @override
  bool get isDefault => false;

  @override
  List<String> get dependsOn => [];

  @override
  Map<String, String> get dependencies => {'dio': '^5.4.0'};

  @override
  Map<String, String> get devDependencies => {};

  @override
  Map<String, String> generateFiles(ProjectConfig config) => {
        'lib/core/api/api_client.dart':
            ApiClientTemplate.generateApiClient(config),
        'lib/core/api/api_exceptions.dart':
            ApiClientTemplate.generateApiExceptions(config),
        'lib/core/api/logging_interceptor.dart':
            ApiClientTemplate.generateLoggingInterceptor(config),
      };

  @override
  List<String> mainImports(ProjectConfig config) => [];

  @override
  List<String> mainSetupLines(ProjectConfig config) => [];

  @override
  List<String> locatorImports(ProjectConfig config) => config.hasModule('locator')
      ? ['package:${config.appNameSnakeCase}/core/api/api_client.dart']
      : [];

  @override
  List<String> locatorRegistrations(ProjectConfig config) =>
      config.hasModule('locator')
          ? ['locator.registerLazySingleton<ApiClient>(() => ApiClient());']
          : [];

  @override
  List<String> providerDeclarations(ProjectConfig config) => [];

  @override
  List<String> appImports(ProjectConfig config) => [];
}
