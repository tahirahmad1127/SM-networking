import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'retailers_cache.dart';

/// Detects app reinstall (including when Android restores backed-up prefs).
class InstallSession {
  static const _prefsKey = 'INSTALL_SESSION_ID';
  static const _channel =
      MethodChannel('com.smnetworking.app/install_session');

  static Future<String> _currentInstallId() async {
    try {
      final id = await _channel.invokeMethod<String>('getInstallId');
      return id ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Clears persisted session when this install differs from the saved one.
  /// Returns true if a reinstall was detected and data was cleared.
  static Future<bool> clearSessionIfReinstalled(
      SharedPreferences prefs) async {
    final current = await _currentInstallId();
    if (current.isEmpty) return false;

    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved != current) {
      await prefs.clear();
      await RetailerCacheService.clearRetailersCache();
      await RetailerCacheService.clearBanksCache();
      await prefs.setString(_prefsKey, current);
      return true;
    }

    if (saved == null) {
      await prefs.setString(_prefsKey, current);
    }
    return false;
  }
}
