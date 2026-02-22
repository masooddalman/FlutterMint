import 'package:flutterforge/src/config/project_config.dart';

class ApiClientTemplate {
  ApiClientTemplate._();

  static String generateApiClient(ProjectConfig config) {
    return '''import 'package:dio/dio.dart';

import 'package:${config.appNameSnakeCase}/core/api/api_exceptions.dart';
import 'package:${config.appNameSnakeCase}/core/api/logging_interceptor.dart';

class ApiClient {
  ApiClient({String? baseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? 'https://api.example.com',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(LoggingInterceptor());
    // Add more interceptors here (e.g., AuthInterceptor)
  }

  late final Dio _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<T> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        queryParameters: queryParameters,
      );
      return response.data as T;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer \$token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
''';
  }

  static String generateApiExceptions(ProjectConfig config) {
    return '''import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timed out',
          statusCode: e.response?.statusCode,
        );
      case DioExceptionType.badResponse:
        return ApiException(
          message: e.response?.statusMessage ?? 'Bad response',
          statusCode: e.response?.statusCode,
          data: e.response?.data,
        );
      case DioExceptionType.cancel:
        return ApiException(message: 'Request cancelled');
      default:
        return ApiException(
          message: e.message ?? 'Network error',
        );
    }
  }

  final String message;
  final int? statusCode;
  final dynamic data;

  @override
  String toString() => 'ApiException(\$statusCode): \$message';
}
''';
  }

  static String generateLoggingInterceptor(ProjectConfig config) {
    final logImport = config.hasModule('logging')
        ? "import 'package:${config.appNameSnakeCase}/core/services/logger_service.dart';"
        : '';
    final logCall = config.hasModule('logging') ? 'LoggerService' : '_log';
    final logHelper = config.hasModule('logging')
        ? ''
        : '''

  // ignore: unused_element
  static void _log(String message, {String? tag}) {
    // ignore: avoid_print
    print('[\${tag ?? "HTTP"}] \$message');
  }''';

    return '''import 'package:dio/dio.dart';
$logImport

class LoggingInterceptor extends Interceptor {$logHelper

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    $logCall.debug(
      '\${options.method} \${options.uri}',
      tag: 'HTTP',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    $logCall.debug(
      '\${response.statusCode} \${response.requestOptions.uri}',
      tag: 'HTTP',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    $logCall.error(
      '\${err.response?.statusCode} \${err.requestOptions.uri}',
      tag: 'HTTP',
    );
    handler.next(err);
  }
}
''';
  }
}
