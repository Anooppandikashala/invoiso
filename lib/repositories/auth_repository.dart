import 'package:invoiso/models/user.dart';

abstract class AuthRepository {
  Future<User?> getUser(String username, String password);
  Future<User?> getUserByUsername(String username);
  Future<List<User>> getAllUsers();
  Future<User?> getUserById(String id);
  Future<void> insertUser(User user);
  Future<void> updateUser(User user);
  Future<void> updatePassword(String id, String newPassword);
  Future<void> markPasswordChanged(String id);
  Future<bool> userExists(String userId);
  Future<bool> deleteUserSafely(String userId);
  Future<void> logoutAndSessionReset();
}