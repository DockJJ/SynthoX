import 'api_service.dart';

class UsersService {
  final ApiService _api = ApiService();

  Future<dynamic> searchUsers(String q, {int limit = 20}) async {
    return _api.get('/api/users/search?q=$q&limit=$limit');
  }

  Future<dynamic> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    return _api.patch('/api/users/me', {
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    });
  }
}
