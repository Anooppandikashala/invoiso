import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordUtils {
  /// Returns a SHA-256 hex hash of the given plain-text password.
  /// Kept for backward compatibility during migration.
  static String hash(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generates a cryptographically secure random salt (32 bytes, base64url encoded).
  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Returns an HMAC-SHA256 hex hash of the password using the given salt.
  static String hashWithSalt(String password, String salt) {
    final key = utf8.encode(salt);
    final message = utf8.encode(password);
    final hmac = Hmac(sha256, key);
    return hmac.convert(message).toString();
  }

  /// Verifies a password against a stored hash.
  /// If [salt] is null, falls back to plain SHA-256 (legacy accounts).
  /// If [salt] is provided, uses HMAC-SHA256.
  static bool verify(String password, String storedHash, String? salt) {
    if (salt == null) {
      return hash(password) == storedHash;
    }
    return hashWithSalt(password, salt) == storedHash;
  }
}
