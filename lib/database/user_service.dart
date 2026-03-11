import 'package:invoiso/models/user.dart';
import 'database_helper.dart';
import '../utils/app_logger.dart';
import '../utils/password_utils.dart';

const _tag = 'UserService';

class UserService {
  static final dbHelper = DatabaseHelper();

  // ─────────────────────────────────────────────
  // CRUD for User

  /// Looks up a user by username and verifies the password.
  /// Supports both legacy SHA-256 (salt == null) and HMAC-SHA256.
  static Future<User?> getUser(String username, String password) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (result.isEmpty) return null;

    final user = User.fromMap(result.first);
    if (PasswordUtils.verify(password, user.password, user.salt)) {
      return user;
    }
    return null;
  }

  static Future<User?> getUserByUsername(String username) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (result.isNotEmpty) return User.fromMap(result.first);
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

  /// Inserts a new user with a fresh salt + HMAC-SHA256 hash.
  static Future<void> insertUser(User user) async {
    final db = await dbHelper.database;
    final salt = PasswordUtils.generateSalt();
    final hashedPw = PasswordUtils.hashWithSalt(user.password, salt);
    final userToInsert = User(
      id: user.id,
      username: user.username,
      password: hashedPw,
      userType: user.userType,
      salt: salt,
      passwordChanged: user.passwordChanged,
    );
    await db.insert('users', userToInsert.toMap());
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

  /// Updates the password for a user: generates a new salt, re-hashes, and
  /// sets password_changed = 1.
  static Future<void> updatePassword(String id, String newPassword) async {
    final db = await dbHelper.database;
    final salt = PasswordUtils.generateSalt();
    final hashedPw = PasswordUtils.hashWithSalt(newPassword, salt);
    await db.update(
      'users',
      {
        'password': hashedPw,
        'salt': salt,
        'password_changed': 1,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Marks password_changed = 1 for the given user.
  static Future<void> markPasswordChanged(String id) async {
    final db = await dbHelper.database;
    await db.update(
      'users',
      {'password_changed': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<bool> userExists(String userId) async {
    final db = await dbHelper.database;
    try {
      final result = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      AppLogger.e(_tag, 'Error checking if user exists', e);
      return false;
    }
  }

  static Future<int> _deleteUser(String userId) async {
    final db = await dbHelper.database;
    try {
      final result = await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      AppLogger.d(_tag, 'User deleted successfully. Rows affected: $result');
      return result;
    } catch (e) {
      AppLogger.e(_tag, 'Error deleting user', e);
      throw Exception('Failed to delete user: $e');
    }
  }

  static Future<bool> deleteUserSafely(String userId) async {
    try {
      final exists = await userExists(userId);
      if (!exists) {
        AppLogger.w(_tag, 'User with ID $userId does not exist');
        return false;
      }
      final result = await _deleteUser(userId);
      return result > 0;
    } catch (e) {
      AppLogger.e(_tag, 'Error in safe delete', e);
      return false;
    }
  }
}
