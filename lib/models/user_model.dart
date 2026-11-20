class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {String? token}) {
    // Check if user data is nested (common in our backend structure)
    final userData = json['data'] != null ? json['data']['user'] : json;
    
    return UserModel(
      id: userData['_id'] ?? userData['id'],
      name: userData['name'],
      email: userData['email'],
      role: userData['role'],
      token: token ?? json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
    };
  }
}
