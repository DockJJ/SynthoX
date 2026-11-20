import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _role;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  AuthProvider() {
    _loadUser();
  }

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get role => _role;
  Future<String?> getAccessToken() => _storage.read(key: 'accessToken');

  Future<void> _loadUser() async {
    try {
      final accessToken = await _storage.read(key: 'accessToken');
      if (accessToken == null) {
        notifyListeners();
        return;
      }
      final result = await _authService.getMe(accessToken);
      if (result['success'] == true) {
        _user = result['user'] as UserModel;
      } else {
        await _storage.deleteAll();
        _user = null;
      }
      _role = await _storage.read(key: 'user_role');
    } catch (_) {
      await _storage.deleteAll();
      _user = null;
      _role = null;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(
      String login, String password, String role) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _authService.login(login: login, password: password);
      if (result['success'] == true) {
        await _storage.write(
            key: 'accessToken', value: result['accessToken'] as String);
        await _storage.write(
            key: 'refreshToken', value: result['refreshToken'] as String);
        await _storage.write(key: 'user_role', value: role);
        _user = result['user'] as UserModel;
        _role = role;
        _isLoading = false;
        notifyListeners();
        return {'success': true};
      } else {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': result['message']};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> signup({
    required String email,
    required String username,
    required String displayName,
    required String password,
    required String role,
    String? avatarUrl,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _authService.signup(
        email: email,
        username: username,
        displayName: displayName,
        password: password,
        avatarUrl: avatarUrl,
      );
      if (result['success'] == true) {
        await _storage.write(
            key: 'accessToken', value: result['accessToken'] as String);
        await _storage.write(
            key: 'refreshToken', value: result['refreshToken'] as String);
        await _storage.write(key: 'user_role', value: role);
        _user = result['user'] as UserModel;
        _role = role;
        _isLoading = false;
        notifyListeners();
        return {'success': true};
      } else {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': result['message']};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(key: 'refreshToken');
      await _authService.logout(refreshToken: refreshToken);
    } catch (_) {
      // best-effort
    }
    await _storage.deleteAll();
    _user = null;
    _role = null;
    notifyListeners();
  }
}
