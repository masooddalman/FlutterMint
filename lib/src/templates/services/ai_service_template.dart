import 'package:fluttermint/src/config/project_config.dart';

class AiServiceTemplate {
  AiServiceTemplate._();

  static String generateAiService(ProjectConfig config) {
    final usesDio = config.hasModule('api');
    final dioImport = usesDio
        ? "import 'package:dio/dio.dart';"
        : "import 'dart:convert';\nimport 'dart:io';";

    return '''$dioImport

class AiConfig {
  const AiConfig({
    required this.apiKey,
    required this.baseUrl,
    this.model = 'default',
    this.maxTokens = 1024,
    this.temperature = 0.7,
  });

  final String apiKey;
  final String baseUrl;
  final String model;
  final int maxTokens;
  final double temperature;
}

class AiMessage {
  const AiMessage({
    required this.role,
    required this.content,
  });

  factory AiMessage.user(String content) =>
      AiMessage(role: 'user', content: content);

  factory AiMessage.assistant(String content) =>
      AiMessage(role: 'assistant', content: content);

  factory AiMessage.system(String content) =>
      AiMessage(role: 'system', content: content);

  final String role;
  final String content;

  Map<String, String> toJson() => {'role': role, 'content': content};
}

class AiResponse {
  const AiResponse({
    required this.content,
    required this.rawResponse,
  });

  final String content;
  final Map<String, dynamic> rawResponse;
}

class AiService {
  AiService({required this.config})${usesDio ? '' : ''};

${usesDio ? _dioBasedService() : _httpBasedService()}
  final AiConfig config;

  Future<AiResponse> sendMessage(String message) async {
    return chat([AiMessage.user(message)]);
  }

  Future<AiResponse> chat(List<AiMessage> messages) async {
    final body = {
      'model': config.model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'max_tokens': config.maxTokens,
      'temperature': config.temperature,
    };

    final responseData = await _post('/chat/completions', body);

    final content = _extractContent(responseData);
    return AiResponse(content: content, rawResponse: responseData);
  }

  String _extractContent(Map<String, dynamic> data) {
    // Standard OpenAI-compatible format
    if (data.containsKey('choices')) {
      final choices = data['choices'] as List;
      if (choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>;
        return message['content'] as String? ?? '';
      }
    }
    // Fallback: try common response fields
    if (data.containsKey('content')) {
      return data['content'] as String;
    }
    if (data.containsKey('text')) {
      return data['text'] as String;
    }
    return data.toString();
  }
}
''';
  }

  static String _dioBasedService() {
    return '''  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer \${config.apiKey}',
      },
    ),
  );

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(path, data: body);
    return response.data ?? {};
  }

''';
  }

  static String _httpBasedService() {
    return '''  final HttpClient _httpClient = HttpClient();

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('\${config.baseUrl}\$path');
    final request = await _httpClient.postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Authorization', 'Bearer \${config.apiKey}');
    request.write(jsonEncode(body));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    return jsonDecode(responseBody) as Map<String, dynamic>;
  }

''';
  }
}
