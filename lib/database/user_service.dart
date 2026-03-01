import 'package:invoiso/models/user.dart';
import 'database_helper.dart';
import '../utils/password_utils.dart';

class UserService {
  static final dbHelper = DatabaseHelper();

  // ─────────────────────────────────────────────
  // CRUD for User
  static Future<User?> getUser(String username, String password) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, PasswordUtils.hash(password)],
    );

    if (result.isNotEmpty) {
      final user = result.first;
      return User.fromMap(user);
    }

    return null;
  }

  static Future<List<User>> getAllUsers() async {
    final db = await dbHelper.database;
    final maps = await db.query('users');
    return maps.map((map) => User.fromMap(map)).toList();
  }

  static Future<User?> getUserById(String id) async {
    final db = await dbHelper.database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (result.isNotEmpty) return User.fromMap(result.first);
    return null;
  }

  static Future<void> insertUser(User user) async {
    final db = await dbHelper.database;
    final userWithHashedPassword = User(
      id: user.id,
      username: user.username,
      password: PasswordUtils.hash(user.password),
      userType: user.userType,
    );
    await db.insert('users', userWithHashedPassword.toMap());
  }

  static Future<void> updateUser(User user) async {
    final db = await dbHelper.database;
    // Deliberately excludes 'password' — use updatePassword() to change passwords.
    await db.update(
      'users',
      {'username': user.username, 'user_type': user.userType},
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  static Future<void> updatePassword(String id, String newPassword) async {
    final db = await dbHelper.database;
    await db.update(
      'users',
      {'password': PasswordUtils.hash(newPassword)},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<bool> userExists(String userId) async {
    final db = await dbHelper.database;

    try {
      final result = await db.query(
        'users', // Replace with your actual table name
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      return result.isNotEmpty;
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  static Future<int> _deleteUser(String userId) async {
    final db = await dbHelper.database;

    try {
      // Delete the user from the database
      int result = await db.delete(
        'users', // Replace with your actual table name
        where: 'id = ?',
        whereArgs: [userId],
      );

      print('User deleted successfully. Rows affected: $result');
      return result;
    } catch (e) {
      print('Error deleting user: $e');
      throw Exception('Failed to delete user: $e');
    }
  }

  static Future<bool> deleteUserSafely(String userId) async {
    try {
      // Check if user exists first
      bool exists = await userExists(userId);
      if (!exists) {
        print('User with ID $userId does not exist');
        return false;
      }

      // Delete the user
      int result = await _deleteUser(userId);
      return result > 0;
    } catch (e) {
      print('Error in safe delete: $e');
      return false;
    }
  }
}