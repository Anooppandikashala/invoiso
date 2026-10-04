import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:invoiso/services/analytics/cloudflare_analytics_service.dart';

class SessionManager {
  static Timer? _timer;
  static VoidCallback? _onTimeout;
  static const _timeoutDuration = Duration(minutes: 30);
  static bool _sessionExpired = false;
  static bool _hooksAdded = false;

  /// Starts the session timer. Calls [onTimeout] when the session expires.
  static void initialize(void Function() onTimeout) {
    _onTimeout = () {
      _sessionExpired = true;
      onTimeout();
    };
    _sessionExpired = false;
    unawaited(CloudflareAnalyticsService.sendHeartbeat());
    // App-wide hooks so any tap or key press counts as activity — including
    // dialogs, pushed screens and keyboard-only typing.
    if (!_hooksAdded) {
      GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
      HardwareKeyboard.instance.addHandler(_onKey);
      _hooksAdded = true;
    }
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
    if (_hooksAdded) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_onPointer);
      HardwareKeyboard.instance.removeHandler(_onKey);
      _hooksAdded = false;
    }
  }

  static void _onPointer(PointerEvent event) {
    if (event is PointerDownEvent) onUserActivity();
  }

  static bool _onKey(KeyEvent event) {
    onUserActivity();
    return false; // never consume the key
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
