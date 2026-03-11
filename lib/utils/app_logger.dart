import 'package:flutter/foundation.dart';

class AppLogger {
  static void d(String tag, String message) {
    if (kDebugMode) debugPrint('[$tag] $message');
  }

  static void e(String tag, String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[$tag] ERROR: $message');
      if (error != null) debugPrint('  Error: $error');
      if (stack != null) debugPrint('  Stack: $stack');
    }
  }

  static void w(String tag, String message) {
    if (kDebugMode) debugPrint('[$tag] WARN: $message');
  }
}
