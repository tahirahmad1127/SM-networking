import 'package:flutter/material.dart';

import '../../presentation/view/auth/log_in/log_in_view.dart';

/// Global navigator key so code outside the widget tree (the API layer in
/// api_helper.dart) can redirect to the login screen when the backend
/// reports the session has expired - e.g. because this account was
/// force-logged-in from another device.
///
/// Wire this up once in main.dart:
///   MaterialApp(navigatorKey: navigatorKey, ...)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Called once, from api_helper.dart, whenever the backend returns a
/// "Session-expired" 401. Implemented in main.dart: clears the 'USER_DATA'
/// SharedPreferences key and UserProvider's cached session (confirmed
/// against body.dart's login handler, which is where those are set).
Future<void> Function()? onSessionExpired;

bool _isHandlingSessionExpiry = false;

/// Clears session state (via [onSessionExpired], if set) and navigates
/// back to the login flow, removing everything else from the stack.
///
/// Debounced so several requests failing with 401 around the same time
/// don't each try to push a duplicate navigation.
Future<void> handleSessionExpired() async {
  if (_isHandlingSessionExpiry) return;
  _isHandlingSessionExpiry = true;
  try {
    if (onSessionExpired != null) {
      await onSessionExpired!();
    }

    // Confirmed against log_in_view.dart / body.dart (login layout) - this
    // is the actual login screen, reached directly rather than via
    // SplashView, since SplashView would just add its 3-second timer and
    // an extra round trip re-reading prefs we've already just cleared.
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LogInView()),
          (route) => false,
    );
  } finally {
    _isHandlingSessionExpiry = false;
  }
}