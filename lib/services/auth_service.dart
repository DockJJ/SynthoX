import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import '../models/user_model.dart';

class AuthService {
  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'login': login, 'password': password}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && (body['success'] as bool? ?? false)) {
        final data = body['data'] as Map<String, dynamic>;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        return {
          'success': true,
          'user': user,
          'accessToken': data['accessToken'] as String,
          'refreshToken': data['refreshToken'] as String,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] as String? ?? 'Login failed',
        };
      }
    } catch (_) {
      return {'success': false, 'message': 'Network error. Check your connection.'};
    }
  }

  Future<Map<String, dynamic>> signup({
    required String email,
    required String username,
    required String displayName,
    required String password,
    String? avatarUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'displayName': displayName,
          'password': password,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        }),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && (body['success'] as bool? ?? false)) {
        final data = body['data'] as Map<String, dynamic>;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        return {
          'success': true,
          'user': user,
          'accessToken': data['accessToken'] as String,
          'refreshToken': data['refreshToken'] as String,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] as String? ?? 'Signup failed',
        };
      }
    } catch (_) {
      return {'success': false, 'message': 'Network error. Check your connection.'};
    }
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && (body['success'] as bool? ?? false)) {
        final data = body['data'] as Map<String, dynamic>;
        return {
          'success': true,
          'accessToken': data['accessToken'] as String,
          'refreshToken': data['refreshToken'] as String,
        };
      } else {
        return {
          'success': false,
          'message': body['message'] as String? ?? 'Token refresh failed',
        };
      }
    } catch (_) {
      return {'success': false, 'message': 'Network error. Check your connection.'};
    }
  }

  Future<Map<String, dynamic>> logout({String? refreshToken}) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
    } catch (_) {
      // best-effort
    }
    return {'success': true};
  }

  Future<Map<String, dynamic>> getMe(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && (body['success'] as bool? ?? false)) {
        final data = body['data'] as Map<String, dynamic>;
        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        return {'success': true, 'user': user};
      } else {
        return {
          'success': false,
          'message': body['message'] as String? ?? 'Failed to load user',
        };
      }
    } catch (_) {
      return {'success': false, 'message': 'Network error. Check your connection.'};
    }
  }
}
