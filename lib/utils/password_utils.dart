import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordUtils {
  /// Returns a SHA-256 hex hash of the given plain-text password.
  static String hash(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
