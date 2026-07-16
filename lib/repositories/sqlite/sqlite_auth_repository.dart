import 'package:invoiso/database/user_service.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/repositories/auth_repository.dart';


class SqliteAuthRepository implements AuthRepository {
  @override
  Future<bool> deleteUserSafely(String userId) {
    return UserService.deleteUserSafely(userId);
  }

  @override
  Future<List<User>> getAllUsers() {
    return UserService.getAllUsers();
  }

  @override
  Future<User?> getUser(String username, String password) {
    return UserService.getUser(username, password);
  }

  @override
  Future<User?> getUserById(String id) {
    return UserService.getUserById(id);
  }

  @override
  Future<User?> getUserByUsername(String username) {
    return UserService.getUserByUsername(username);
  }

  @override
  Future<void> insertUser(User user) {
    return UserService.insertUser(user);
  }

  @override
  Future<void> markPasswordChanged(String id) {
    return UserService.markPasswordChanged(id);
  }

  @override
  Future<void> updatePassword(String id, String newPassword) {
    return UserService.updatePassword(id, newPassword);
  }

  @override
  Future<void> updateUser(User user) {
    return UserService.updateUser(user);
  }

  @override
  Future<bool> userExists(String userId) {
    return UserService.userExists(userId);
  }

  @override
  Future<void> logoutAndSessionReset() {
    return UserService.logoutAndSessionReset();
  }

}