import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  final _storage = const FlutterSecureStorage();
  final _authService = AuthService();

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    // Try to auto-login on initialization
    _loadUser();
  }

  Future<void> _loadUser() async {
    // Logic to load user from storage can be added here
    // For now, we'll just check if a token exists
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      // In a real app, you'd verify the token with the backend
      // and fetch the user profile.
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.login(email, password);

    if (result['success']) {
      _user = result['user'];
      await _storage.write(key: 'jwt_token', value: result['token']);
      await _storage.write(key: 'user_role', value: _user!.role);
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
    required String passwordConfirm,
    required String role,
    String? phone,
    String? dateOfBirth,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.signup(
      name: name,
      email: email,
      password: password,
      passwordConfirm: passwordConfirm,
      role: role,
      phone: phone,
      dateOfBirth: dateOfBirth,
    );

    if (result['success']) {
      _user = result['user'];
      await _storage.write(key: 'jwt_token', value: result['token']);
      await _storage.write(key: 'user_role', value: _user!.role);
    }

    _isLoading = false;
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    _user = null;
    await _storage.deleteAll();
    notifyListeners();
  }
}
