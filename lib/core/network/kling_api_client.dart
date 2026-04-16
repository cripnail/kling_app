import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:kling_app/core/network/config/kling_api_config.dart';
import 'package:kling_app/core/network/kling_exceptions.dart';
export 'package:kling_app/core/network/kling_exceptions.dart';

class KlingApiClient {
  String _generateJwt() {
    final header = jsonEncode({'alg': 'HS256', 'typ': 'JWT'});
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final ak = KlingApiConfig.accessKey;
    final payloadMap = <String, dynamic>{
      'iss': ak,
      'exp': (now + 3600).toInt(),
      'nbf': now.toInt(),
    };
    final payload = jsonEncode(payloadMap);
    final encodedHeader = base64Url.encode(utf8.encode(header)).replaceAll('=', '');
    final encodedPayload = base64Url.encode(utf8.encode(payload)).replaceAll('=', '');
    final signatureInput = '$encodedHeader.$encodedPayload';
    final hmac = Hmac(sha256, utf8.encode(KlingApiConfig.secretKey));
    final signature = base64Url.encode(hmac.convert(utf8.encode(signatureInput)).bytes).replaceAll('=', '');
    return '$signatureInput.$signature';
  }

  Future<http.Response> _sendRequest(
    String method,
    Uri url,
    Map<String, String> headers, {
    Map<String, dynamic>? body,
  }) async {
    if (method == 'POST') {
      return http.post(url, headers: headers, body: body != null ? jsonEncode(body) : null);
    }
    return http.get(url, headers: headers);
  }

  bool _shouldRetry(int statusCode) {
    return statusCode == 429 || (statusCode >= 500 && statusCode < 600);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    int retryCount = 0,
  }) async {
    final url = Uri.parse('${KlingApiConfig.baseUrl}$path');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_generateJwt()}',
    };

    try {
      final response = await _sendRequest(method, url, headers, body: body)
          .timeout(const Duration(seconds: 30));

      if (_shouldRetry(response.statusCode)) {
        if (retryCount < 3) {
          await Future.delayed(Duration(seconds: 1 << retryCount));
          return _request(method, path, body: body, retryCount: retryCount + 1);
        }
        throw KlingRateLimitException('Лимит запросов превышен');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw KlingApiException('Ошибка сервера', statusCode: response.statusCode);
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on SocketException catch (e) {
      throw KlingApiException('Нет подключения к сети: $e');
    } on FormatException catch (e) {
      throw KlingApiException('Неверный формат ответа: $e');
    }
  }

  Future<String> generateImage(String prompt) async {
    final response = await _request('POST', '/v1/images/generations', body: {
      'prompt': prompt,
      'n': 1,
      'size': '1024x1024',
    });

    final data = response['data'] as Map<String, dynamic>?;
    final taskId = data?['task_id'] as String?;
    if (taskId == null) {
      throw KlingApiException('Нет ответа от API');
    }
    return taskId;
  }

  Future<Map<String, dynamic>> getTaskStatus(String taskId) async {
    final response = await _request('GET', '/v1/images/generations/$taskId');
    return response;
  }
}
