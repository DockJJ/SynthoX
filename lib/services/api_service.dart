import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedException implements Exception {
  @override
  String toString() => 'UnauthorizedException: session expired';
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _buildHeaders({String? accessToken}) async {
    final token = accessToken ?? await _storage.read(key: 'accessToken');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _parseResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final success = body['success'] as bool? ?? false;
    if (!success) {
      final message = body['message'] as String? ?? 'Unknown error';
      throw ApiException(message, response.statusCode);
    }
    return body['data'];
  }

  Future<dynamic> _executeWithRefresh(
      Future<http.Response> Function(Map<String, String> headers) request) async {
    final headers = await _buildHeaders();
    var response = await request(headers);

    if (response.statusCode == 401) {
      // Attempt token refresh
      final refreshToken = await _storage.read(key: 'refreshToken');
      if (refreshToken == null) {
        await _storage.deleteAll();
        throw UnauthorizedException();
      }

      final refreshResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (refreshResponse.statusCode == 200) {
        final refreshBody = jsonDecode(refreshResponse.body) as Map<String, dynamic>;
        final refreshSuccess = refreshBody['success'] as bool? ?? false;
        if (refreshSuccess) {
          final data = refreshBody['data'] as Map<String, dynamic>;
          final newAccessToken = data['accessToken'] as String;
          final newRefreshToken = data['refreshToken'] as String;
          await _storage.write(key: 'accessToken', value: newAccessToken);
          await _storage.write(key: 'refreshToken', value: newRefreshToken);

          // Retry once with new token
          final newHeaders = await _buildHeaders(accessToken: newAccessToken);
          response = await request(newHeaders);
        } else {
          await _storage.deleteAll();
          throw UnauthorizedException();
        }
      } else {
        await _storage.deleteAll();
        throw UnauthorizedException();
      }
    }

    return _parseResponse(response);
  }

  String _normalizeUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    if (cleanPath.startsWith('/api/')) {
      return '${ApiConfig.baseUrl}$cleanPath';
    }
    return '${ApiConfig.apiBaseUrl}$cleanPath';
  }

  Future<dynamic> get(String path) async {
    return _executeWithRefresh((headers) => http.get(
          Uri.parse(_normalizeUrl(path)),
          headers: headers,
        ));
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    return _executeWithRefresh((headers) => http.post(
          Uri.parse(_normalizeUrl(path)),
          headers: headers,
          body: jsonEncode(body),
        ));
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    return _executeWithRefresh((headers) => http.patch(
          Uri.parse(_normalizeUrl(path)),
          headers: headers,
          body: jsonEncode(body),
        ));
  }

  Future<dynamic> delete(String path) async {
    return _executeWithRefresh((headers) => http.delete(
          Uri.parse(_normalizeUrl(path)),
          headers: headers,
        ));
  }
}
