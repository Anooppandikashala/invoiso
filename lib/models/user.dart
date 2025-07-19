class User {
  final String id;
  final String username;
  final String password;
  final String userType; // 'admin' or 'user'

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.userType,
  });

  // Optional: toMap and fromMap for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'user_type': userType,
    };
  }

  bool isAdmin()
  {
    return userType.toString().toLowerCase() == "admin";
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      userType: map['user_type'],
    );
  }
}