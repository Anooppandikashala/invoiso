class User {
  final String id;
  final String username;
  final String password;
  final String userType; // 'admin' or 'user'
  final String? salt;
  final bool passwordChanged;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.userType,
    this.salt,
    this.passwordChanged = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'user_type': userType,
      'salt': salt,
      'password_changed': passwordChanged ? 1 : 0,
    };
  }

  bool isAdmin() {
    return userType.toString().toLowerCase() == 'admin';
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      userType: map['user_type'],
      salt: map['salt'] as String?,
      passwordChanged: (map['password_changed'] as int? ?? 1) == 1,
    );
  }
}
