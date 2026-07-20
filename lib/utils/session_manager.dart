import 'dart:async';

import 'package:invoiso/services/analytics/cloudflare_analytics_service.dart';

class SessionManager {
  static Timer? _timer;
  static VoidCallback? _onTimeout;
  static const _timeoutDuration = Duration(minutes: 30);
  static bool _sessionExpired = false;

  /// Starts the session timer. Calls [onTimeout] when the session expires.
  static void initialize(void Function() onTimeout) {
    _onTimeout = () {
      _sessionExpired = true;
      onTimeout();
    };
    _sessionExpired = false;
    unawaited(CloudflareAnalyticsService.sendHeartbeat());
    _resetTimer();
  }

  /// Resets the session timer (call on any user activity).
  static void onUserActivity() {
    if (_onTimeout == null) return;

    if (_sessionExpired) {
      _sessionExpired = false;
      unawaited(CloudflareAnalyticsService.sendHeartbeat());
    }
    _resetTimer();
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
