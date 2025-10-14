import 'package:invoiso/models/user.dart';
import 'database_helper.dart';

class UserService {
  static final dbHelper = DatabaseHelper();

  // ─────────────────────────────────────────────
  // CRUD for User
  static Future<User?> getUser(String username, String password) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
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

  static Future<void> insertUser(User user) async {
    final db = await dbHelper.database;
    await db.insert('users', user.toMap());
  }

  static Future<void> updateUser(User user) async {
    final db = await dbHelper.database;
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  static Future<void> updatePassword(String id, String newPassword) async {
    final db = await dbHelper.database;
    await db.update('users', {'password': newPassword}, where: 'id = ?', whereArgs: [id]);
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