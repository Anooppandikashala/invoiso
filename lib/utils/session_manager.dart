import 'dart:async';

class SessionManager {
  static Timer? _timer;
  static VoidCallback? _onTimeout;
  static const _timeoutDuration = Duration(minutes: 30);

  /// Starts the session timer. Calls [onTimeout] when the session expires.
  static void initialize(void Function() onTimeout) {
    _onTimeout = onTimeout;
    _resetTimer();
  }

  /// Resets the session timer (call on any user activity).
  static void onUserActivity() {
    if (_onTimeout != null) {
      _resetTimer();
    }
  }

  /// Cancels the timer and clears state.
  static void dispose() {
    _timer?.cancel();
    _timer = null;
    _onTimeout = null;
  }

  static void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(_timeoutDuration, () {
      _onTimeout?.call();
    });
  }
}

// Re-export VoidCallback type alias so callers don't need dart:ui
typedef VoidCallback = void Function();
