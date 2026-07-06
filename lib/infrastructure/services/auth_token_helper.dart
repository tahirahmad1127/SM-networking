import 'package:shared_preferences/shared_preferences.dart';
import 'package:sm_networking/infrastructure/model/user.dart';

import '../../injection_container.dart';

/// Reads the current session token out of SharedPreferences.
///
/// Confirmed against log_in body.dart / splash body.dart: the full
/// UserModel (which includes `token`) is cached under the 'USER_DATA' key
/// on login, so this reads the same blob rather than a separate token key.
///
/// Returns null if there's no cached session (e.g. logged out).
Future<String?> getAuthToken() async {
  try {
    final prefs = sl<SharedPreferences>();
    final raw = prefs.getString('USER_DATA');
    if (raw == null || raw.isEmpty) return null;
    return userModelFromJson(raw).token;
  } catch (_) {
    return null;
  }
}