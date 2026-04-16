import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class KlingApiException implements Exception {
  final String message;
  final int? statusCode;
  KlingApiException(this.message, {this.statusCode});
  @override
  String toString() => 'KlingApiException: $message (status: $statusCode)';
}

class KlingRateLimitException implements Exception {
  final String message;
  KlingRateLimitException(this.message);
  @override
  String toString() => 'KlingRateLimitException: $message';
}

class KlingApiClient {
  static const _accessKey = 'ADBETNd4mYm9ktTbkJamYQJ8EhbPPCLJ';
  static const _secretKey = 'mnTYffRb3CbmdMQadHFF3dgrbQrDrLrP';
  static const _baseUrl = 'https://api.klingai.com';

  String _generateJwt() {
    final header = jsonEncode({'alg': 'HS256', 'typ': 'JWT'});
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final ak = _accessKey;
    final payloadMap = <String, dynamic>{
      'iss': ak,
      'exp': (now + 3600).toInt(),
      'nbf': now.toInt(),
    };
    if (kDebugMode) print('🔑 JWT_PAYLOAD: ${jsonEncode(payloadMap)}');
    final payload = jsonEncode(payloadMap);
    final encodedHeader = base64Url.encode(utf8.encode(header)).replaceAll('=', '');
    final encodedPayload = base64Url.encode(utf8.encode(payload)).replaceAll('=', '');
    final signatureInput = '$encodedHeader.$encodedPayload';
    final hmac = Hmac(sha256, utf8.encode(_secretKey));
    final signature = base64Url.encode(hmac.convert(utf8.encode(signatureInput)).bytes).replaceAll('=', '');
    return '$signatureInput.$signature';
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    int retryCount = 0,
  }) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_generateJwt()}',
    };

    try {
      final response = await (method == 'POST'
          ? http.post(url, headers: headers, body: body != null ? jsonEncode(body) : null)
          : http.get(url, headers: headers)).timeout(const Duration(seconds: 30));

      if (response.statusCode == 429 || (response.statusCode >= 500 && response.statusCode < 600)) {
        if (retryCount < 3) {
          await Future.delayed(Duration(seconds: 1 << retryCount));
          return _request(method, path, body: body, retryCount: retryCount + 1);
        }
        throw KlingRateLimitException('Rate limit exceeded after retries');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (kDebugMode) print('🔴 HTTP ERROR ${response.statusCode}: ${response.body}');
        throw KlingApiException('Request failed', statusCode: response.statusCode);
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on SocketException catch (e) {
      throw KlingApiException('Network error: $e');
    } on FormatException catch (e) {
      throw KlingApiException('Invalid response format: $e');
    }
  }

  Future<String> generateImage(String prompt) async {
    if (kDebugMode) print('📡 REQUEST URL: $_baseUrl/v1/images/generations');
    final response = await _request('POST', '/v1/images/generations', body: {
      'prompt': prompt,
      'n': 1,
      'size': '1024x1024',
    });

    final data = response['data'] as Map<String, dynamic>?;
    final taskId = data?['task_id'] as String?;
    if (taskId == null) {
      throw KlingApiException('No task_id in response');
    }
    return taskId;
  }

  Future<Map<String, dynamic>> getTaskStatus(String taskId) async {
    if (kDebugMode) print('📡 STATUS URL: $_baseUrl/v1/images/generations/$taskId');
    final response = await _request('GET', '/v1/images/generations/$taskId');
    return response;
  }
}
