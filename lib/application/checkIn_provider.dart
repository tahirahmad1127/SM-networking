import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:sm_networking/presentation/elements/my_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CheckInProvider extends ChangeNotifier {
  static const _keyIsCheckedIn = "isCheckedIn";
  static const _keyCheckInTime = "CHECK_IN_TIME";
  static const _keyCheckOutTime = "CHECK_OUT_TIME";

  bool _isCheckedIn = false;
  String? _checkInTime;
  String? _checkOutTime;

  String? _allowedCheckInTime;
  String? _allowedCheckOutTime;

  // Getters
  bool get isCheckedIn => _isCheckedIn;
  String? get checkInTime => _checkInTime;
  String? get checkOutTime => _checkOutTime;
  String? get allowedCheckInTime => _allowedCheckInTime;
  String? get allowedCheckOutTime => _allowedCheckOutTime;

  String get formattedCheckInTime {
    if (_checkInTime == null) return '--:--';
    try {
      final date = DateTime.parse(_checkInTime!);
      return DateFormat('hh:mm a').format(date);
    } catch (e) {
      return '--:--';
    }
  }

  String get formattedCheckOutTime {
    if (_checkOutTime == null) return '--:--';
    try {
      final date = DateTime.parse(_checkOutTime!);
      return DateFormat('hh:mm a').format(date);
    } catch (e) {
      return '--:--';
    }
  }

  void setAllowedTimes({String? checkInTime, String? checkOutTime}) {
    _allowedCheckInTime = checkInTime;
    _allowedCheckOutTime = checkOutTime;

    final checkInDisplay = formattedAllowedCheckInTime;
    final checkOutDisplay = formattedAllowedCheckOutTime;

    AppLogger.debug(
        "🕐 Allowed Times Updated:\n"
            "   Check-In Starts At: $checkInDisplay\n"
            "   Check-In Ends/Auto Check-Out: $checkOutDisplay\n"
            "   Raw Values: CheckIn=$checkInTime, CheckOut=$checkOutTime"
    );
    notifyListeners();
  }

  DateTime? _parseTimeToday(String? timeStr) {
    if (timeStr == null) return null;
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      AppLogger.debug("Failed to parse time: $timeStr");
      return null;
    }
  }

  DateTime? get checkInDateTime {
    return _parseTimeToday(_allowedCheckInTime);
  }

  DateTime? get checkOutDateTime {
    return _parseTimeToday(_allowedCheckOutTime);
  }

  /// Load status from SharedPreferences
  Future<void> loadStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final wasCheckedIn = _isCheckedIn;

    _isCheckedIn = prefs.getBool(_keyIsCheckedIn) ?? false;
    _checkInTime = prefs.getString(_keyCheckInTime);
    _checkOutTime = prefs.getString(_keyCheckOutTime);

    if (wasCheckedIn && !_isCheckedIn) {
      AppLogger.debug("🔴 State Change: User was checked OUT");
    } else if (!wasCheckedIn && _isCheckedIn) {
      AppLogger.debug("🟢 State Change: User was checked IN");
    }

    AppLogger.debug(
      "📊 Current Status => "
          "isCheckedIn: $_isCheckedIn, "
          "checkInTime: $_checkInTime, "
          "checkOutTime: $_checkOutTime",
    );

    notifyListeners();
  }

  /// NEW: Force reload from disk (bypasses cache)
  Future<void> forceReload() async {
    log("🔄 Force reloading check-in status from SharedPreferences...");

    final prefs = await SharedPreferences.getInstance();

    // Force read from disk by calling reload first
    await prefs.reload();

    final wasCheckedIn = _isCheckedIn;

    _isCheckedIn = prefs.getBool(_keyIsCheckedIn) ?? false;
    _checkInTime = prefs.getString(_keyCheckInTime);
    _checkOutTime = prefs.getString(_keyCheckOutTime);

    if (wasCheckedIn != _isCheckedIn) {
      AppLogger.debug("⚠️ CHECK-IN STATUS CHANGED: $wasCheckedIn → $_isCheckedIn");
    }

    log(
      "✅ Force Reload Complete => "
          "isCheckedIn: $_isCheckedIn, "
          "checkInTime: $_checkInTime, "
          "checkOutTime: $_checkOutTime",
    );

    // CRITICAL: Always notify listeners to force UI rebuild
    notifyListeners();
  }

  Future<void> checkIn() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();

    _isCheckedIn = true;
    _checkInTime = now;
    _checkOutTime = null;

    await prefs.setBool(_keyIsCheckedIn, true);
    await prefs.setString(_keyCheckInTime, now);
    await prefs.remove(_keyCheckOutTime);

    AppLogger.debug("✅ Checked In at: ${DateFormat('hh:mm a').format(DateTime.parse(now))}");
    notifyListeners();
  }

  Future<void> checkOut() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().toIso8601String();

    _isCheckedIn = false;
    _checkOutTime = now;

    await prefs.setBool(_keyIsCheckedIn, false);
    await prefs.setString(_keyCheckOutTime, now);

    AppLogger.debug("✅ Checked Out at: ${DateFormat('hh:mm a').format(DateTime.parse(now))}");
    notifyListeners();
  }

  Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsCheckedIn);
    await prefs.remove(_keyCheckInTime);
    await prefs.remove(_keyCheckOutTime);

    _isCheckedIn = false;
    _checkInTime = null;
    _checkOutTime = null;

    AppLogger.debug("🧹 Cleared Check-In Data");
    notifyListeners();
  }

  bool get isAutoCheckoutDue {
    final checkoutTime = checkOutDateTime;
    if (checkoutTime == null) {
      return DateTime.now().hour >= 17;
    }
    return DateTime.now().isAfter(checkoutTime);
  }

  String get totalHours {
    if (_checkInTime == null || _checkOutTime == null) return '--:--';
    try {
      final start = DateTime.parse(_checkInTime!);
      final end = DateTime.parse(_checkOutTime!);
      final diff = end.difference(start);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--:--';
    }
  }

  bool get canCheckIn {
    final now = DateTime.now();
    final checkInStartTime = checkInDateTime;
    final checkoutTime = checkOutDateTime;

    if (checkInStartTime == null || checkoutTime == null) {
      return now.hour >= 9 && now.hour < 17;
    }

    final isAfterCheckInTime = now.isAfter(checkInStartTime) || now.isAtSameMomentAs(checkInStartTime);
    final isBeforeCheckOutTime = now.isBefore(checkoutTime);

    return isAfterCheckInTime && isBeforeCheckOutTime;
  }

  String get checkInStatusMessage {
    final now = DateTime.now();
    final checkInStartTime = checkInDateTime;
    final checkoutTime = checkOutDateTime;

    if (checkInStartTime == null || checkoutTime == null) {
      return "Check-in available between 9:00 AM and 5:00 PM";
    }

    if (now.isBefore(checkInStartTime)) {
      return "Check-in will be available from ${formattedAllowedCheckInTime}";
    }

    if (now.isAfter(checkoutTime) || now.isAtSameMomentAs(checkoutTime)) {
      return "Check-in period ended at ${formattedAllowedCheckOutTime}";
    }

    return "Check-in available until ${formattedAllowedCheckOutTime}";
  }

  String get formattedAllowedCheckInTime {
    if (_allowedCheckInTime == null) return '09:00 AM';
    try {
      final time = _parseTimeToday(_allowedCheckInTime!);
      if (time == null) return _allowedCheckInTime!;
      return DateFormat('hh:mm a').format(time);
    } catch (e) {
      return _allowedCheckInTime!;
    }
  }

  String get formattedAllowedCheckOutTime {
    if (_allowedCheckOutTime == null) return '05:00 PM';
    try {
      final time = _parseTimeToday(_allowedCheckOutTime!);
      if (time == null) return _allowedCheckOutTime!;
      return DateFormat('hh:mm a').format(time);
    } catch (e) {
      return _allowedCheckOutTime!;
    }
  }
}