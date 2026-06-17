import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sm_networking/presentation/elements/my_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VisitProvider extends ChangeNotifier {
  static const _keyStartVisit = "START_VISIT";
  static const _keyLatitude = "VISIT_LATITUDE";
  static const _keyLongitude = "VISIT_LONGITUDE";
  static const _keyImagePath = "VISIT_IMAGE_PATH";
  static const _keyAccuracy = "VISIT_ACCURACY";
  static const _keyIsNewShop = "IS_NEW_SHOP"; // NEW KEY

  DateTime? _startVisit;
  LatLng? _visitLocation;
  String? _visitImagePath;
  bool _visitAutoLogged = false;
  bool _isCleared = false;
  double? _startLocationAccuracy;
  bool _isNewShop = false; // NEW FIELD - defaults to false

  Timer? _locationCheckTimer;
  Function(String message)? onVisitAutoLogged;
  // Stored so we can pause/resume monitoring without re-passing the callback
  Future<void> Function()? _lastLocationCheckCallback;

  DateTime? get startVisit => _startVisit;
  LatLng? get visitLocation => _visitLocation;
  String? get visitImage => _visitImagePath;
  bool get isVisitAutoLogged => _visitAutoLogged;
  bool get isNewShop => _isNewShop; // NEW GETTER

  /// Save visit data and START location monitoring
  /// ✅ FIXED: Now accepts a callback that returns Future<void>
  Future<void> setStartVisit({
    required LatLng location,
    String? imagePath,
    required Future<void> Function() onLocationCheckCallback,
    double? accuracy,
    bool isNewShop = false, // NEW PARAMETER - defaults to false
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Save time
    await prefs.setString(_keyStartVisit, now.toIso8601String());
    _startVisit = now;

    // Save location
    await prefs.setDouble(_keyLatitude, location.latitude);
    await prefs.setDouble(_keyLongitude, location.longitude);
    _visitLocation = location;

    // Save accuracy
    if (accuracy != null) {
      await prefs.setDouble(_keyAccuracy, accuracy);
      _startLocationAccuracy = accuracy;
    }

    // Save image path
    if (imagePath != null && imagePath.isNotEmpty) {
      await prefs.setString(_keyImagePath, imagePath);
      _visitImagePath = imagePath;
    } else {
      await prefs.remove(_keyImagePath);
      _visitImagePath = null;
    }

    // Save isNewShop flag
    await prefs.setBool(_keyIsNewShop, isNewShop);
    _isNewShop = isNewShop;

    _visitAutoLogged = false;
    _isCleared = false;

    AppLogger.debug("✅ Visit Data Saved:");
    log("   Time: $_startVisit");
    log("   START Location: ${location.latitude}, ${location.longitude}");
    log("   GPS Accuracy: ${accuracy?.toStringAsFixed(2) ?? 'Unknown'} meters");
    log("   Image Path: ${_visitImagePath ?? 'No image'}");
    log("   Is New Shop: $isNewShop"); // NEW LOG

    // Start background location monitoring ONLY if NOT a new shop
    if (!isNewShop) {
      startLocationMonitoring(onLocationCheckCallback);
    } else {
      AppLogger.debug("🏪 New shop visit - skipping auto-monitoring");
    }

    notifyListeners();
  }

  /// Start periodic location checking (every 5 seconds)
  /// ✅ FIXED: Now properly awaits async callback
  void startLocationMonitoring(Future<void> Function() onLocationCheckCallback) {
    _lastLocationCheckCallback = onLocationCheckCallback;
    // Don't start monitoring for new shops
    if (_isNewShop) {
      AppLogger.debug("🏪 New shop visit - monitoring disabled");
      return;
    }

    // Cancel any existing timer
    stopLocationMonitoring();

    log("🎯 Started background location monitoring in VisitProvider");
    log("📍 START Location stored: ${_visitLocation?.latitude}, ${_visitLocation?.longitude}");

    _locationCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      log("⏰ VisitProvider timer tick - checking conditions...");

      // CRITICAL: Check if data was cleared
      if (_isCleared) {
        AppLogger.debug("🔴 Visit data cleared - stopping VisitProvider timer");
        timer.cancel();
        _locationCheckTimer = null;
        return;
      }

      if (_visitAutoLogged) {
        AppLogger.debug("🔴 Visit auto-logged - stopping VisitProvider timer");
        timer.cancel();
        _locationCheckTimer = null;
        return;
      }

      if (_startVisit == null || _visitLocation == null) {
        AppLogger.debug("🔴 No visit data - stopping VisitProvider timer");
        timer.cancel();
        _locationCheckTimer = null;
        return;
      }

      // Skip monitoring if new shop
      if (_isNewShop) {
        AppLogger.debug("🏪 New shop visit - skipping monitoring check");
        timer.cancel();
        _locationCheckTimer = null;
        return;
      }

      AppLogger.debug("✅ VisitProvider timer - calling location check callback");
      log("📍 Comparing against START location: ${_visitLocation?.latitude}, ${_visitLocation?.longitude}");

      // ✅ FIXED: Properly await the async callback
      await onLocationCheckCallback();
    });
  }

  /// Check location and auto-log visit if moved beyond threshold
  Future<void> checkAndAutoLogVisit({
    required LatLng currentLocation,
    required Function() onAutoLogVisit,
    double? currentAccuracy,
    Function(String)? onShowNotification,
  }) async {
    // Don't process if already cleared
    if (_isCleared) {
      AppLogger.debug("⚠️ Visit already cleared - skipping auto-log check");
      return;
    }

    // NEW: Don't auto-log for new shops
    if (_isNewShop) {
      AppLogger.debug("🏪 New shop visit - skipping auto-log check");
      return;
    }

    if (_visitAutoLogged) return;
    if (_startVisit == null || _visitLocation == null) return;

    // CRITICAL: Filter out inaccurate GPS readings
    const double MAX_ACCEPTABLE_ACCURACY = 30.0; // meters

    if (currentAccuracy != null && currentAccuracy > MAX_ACCEPTABLE_ACCURACY) {
      AppLogger.debug("⚠️ Current GPS accuracy too low: ${currentAccuracy.toStringAsFixed(2)}m (max: $MAX_ACCEPTABLE_ACCURACY m)");
      log("   Skipping distance check - waiting for better GPS signal");
      return;
    }

    if (_startLocationAccuracy != null && _startLocationAccuracy! > MAX_ACCEPTABLE_ACCURACY) {
      AppLogger.debug("⚠️ Start location accuracy was too low: ${_startLocationAccuracy!.toStringAsFixed(2)}m");
      log("   Using lenient threshold");
    }

    // Calculate distance
    final distance = calculateDistance(_visitLocation!, currentLocation);

    // Adjust threshold based on GPS accuracy
    double effectiveThreshold = 20.0; // Default 20 meters

    if (currentAccuracy != null || _startLocationAccuracy != null) {
      final maxAccuracy = math.max(
          currentAccuracy ?? 0,
          _startLocationAccuracy ?? 0
      );

      // If GPS accuracy is poor, increase threshold
      // Formula: threshold = 20 + (accuracy * 0.5)
      effectiveThreshold = math.max(20.0, 20.0 + (maxAccuracy * 0.5));

      log("📍 Adjusted threshold based on GPS accuracy:");
      log("   Start accuracy: ${_startLocationAccuracy?.toStringAsFixed(2) ?? 'N/A'}m");
      log("   Current accuracy: ${currentAccuracy?.toStringAsFixed(2) ?? 'N/A'}m");
      log("   Effective threshold: ${effectiveThreshold.toStringAsFixed(2)}m");
    }

    AppLogger.debug("🔍 Checking distance:");
    log("   START location: ${_visitLocation!.latitude}, ${_visitLocation!.longitude}");
    log("   CURRENT location: ${currentLocation.latitude}, ${currentLocation.longitude}");
    log("   Distance: ${distance.toStringAsFixed(2)}m");
    log("   Threshold: ${effectiveThreshold.toStringAsFixed(2)}m");

    if (distance > effectiveThreshold) {
      AppLogger.debug("🚶 User moved >${effectiveThreshold.toStringAsFixed(0)}m - Auto-logging visit");

      _visitAutoLogged = true;

      // Stop monitoring
      stopLocationMonitoring();

      // ✅ Show notification to user
      if (onShowNotification != null) {
        onShowNotification("Visit recorded - You moved away from location");
      }

      // Trigger the callback to log visit
      onAutoLogVisit();

      notifyListeners();
    } else {
      AppLogger.debug("✅ User still within threshold (${distance.toStringAsFixed(2)}m < ${effectiveThreshold.toStringAsFixed(2)}m)");
    }
  }

  /// Resume monitoring using the last stored callback (call after returning from sub-screen)
  void resumeLocationMonitoring() {
    if (_lastLocationCheckCallback != null &&
        _startVisit != null &&
        _visitLocation != null &&
        !_visitAutoLogged &&
        !_isCleared &&
        !_isNewShop) {
      startLocationMonitoring(_lastLocationCheckCallback!);
    }
  }

  /// Stop location monitoring
  void stopLocationMonitoring() {
    if (_locationCheckTimer != null) {
      final wasActive = _locationCheckTimer!.isActive;
      _locationCheckTimer!.cancel();
      _locationCheckTimer = null;
      AppLogger.debug("🛑 Stopped VisitProvider location monitoring timer (was active: $wasActive)");
    } else {
      AppLogger.debug("🛑 stopLocationMonitoring called but timer was already null");
    }
  }

  /// Get saved startVisit data
  Future<DateTime?> getStartVisit() async {
    // Return null immediately if cleared
    if (_isCleared) {
      AppLogger.debug("⚠️ Visit data already cleared - returning null");
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyStartVisit);

    if (saved != null) {
      _startVisit = DateTime.tryParse(saved);

      // Also load location, accuracy, image, and isNewShop flag
      final lat = prefs.getDouble(_keyLatitude);
      final lng = prefs.getDouble(_keyLongitude);
      final accuracy = prefs.getDouble(_keyAccuracy);
      final imagePath = prefs.getString(_keyImagePath);
      final isNewShop = prefs.getBool(_keyIsNewShop) ?? false; // NEW

      if (lat != null && lng != null) {
        _visitLocation = LatLng(lat, lng);
      }

      if (accuracy != null) {
        _startLocationAccuracy = accuracy;
      }

      if (imagePath != null && imagePath.isNotEmpty) {
        _visitImagePath = imagePath;
      }

      _isNewShop = isNewShop; // NEW

      AppLogger.debug("📦 Loaded Visit Data:");
      AppLogger.debug("   Time: $_startVisit");
      AppLogger.debug("   Location: $_visitLocation");
      AppLogger.debug("   Accuracy: ${_startLocationAccuracy?.toStringAsFixed(2) ?? 'N/A'}m");
      AppLogger.debug("   Image Path: $_visitImagePath");
      AppLogger.debug("   Is New Shop: $_isNewShop"); // NEW LOG

      return _startVisit;
    }

    AppLogger.debug("⚠️ No Visit Data found in SharedPreferences");
    return null;
  }

  /// Calculate distance between two points using Haversine formula
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters

    double lat1Rad = point1.latitude * (math.pi / 180);
    double lat2Rad = point2.latitude * (math.pi / 180);
    double deltaLat = (point2.latitude - point1.latitude) * (math.pi / 180);
    double deltaLng = (point2.longitude - point1.longitude) * (math.pi / 180);

    // Haversine formula
    double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
            math.sin(deltaLng / 2) * math.sin(deltaLng / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    double distance = earthRadius * c;

    return distance;
  }

  /// Check if user has moved beyond threshold
  bool hasMovedBeyondThreshold(LatLng currentLocation, {double thresholdMeters = 20}) {
    // Don't process if already cleared - RETURN IMMEDIATELY
    if (_isCleared) {
      AppLogger.debug("⚠️ Visit data cleared - skipping threshold check");
      return false;
    }

    // NEW: For new shops, always return false (don't check threshold)
    if (_isNewShop) {
      AppLogger.debug("🏪 New shop visit - threshold check disabled");
      return false;
    }

    if (_visitLocation == null) {
      AppLogger.debug("⚠️ No saved visit location to compare");
      return false;
    }

    final distance = calculateDistance(_visitLocation!, currentLocation);

    AppLogger.debug("📍 Distance calculation:");
    AppLogger.debug("   From: Lat ${_visitLocation!.latitude}, Lng ${_visitLocation!.longitude}");
    AppLogger.debug("   To:   Lat ${currentLocation.latitude}, Lng ${currentLocation.longitude}");
    AppLogger.debug("   Distance: ${distance.toStringAsFixed(2)} meters (Threshold: $thresholdMeters meters)");

    if (distance > thresholdMeters) {
      AppLogger.debug("   ✅ Threshold EXCEEDED - User moved away!");
    } else {
      AppLogger.debug("   ❌ Still within threshold");
    }

    return distance > thresholdMeters;
  }

  /// Clear saved visit data
  Future<void> clearVisitData() async {
    // Set flag FIRST - this stops ALL operations immediately
    _isCleared = true;
    AppLogger.debug("🚨 _isCleared flag set - all operations should stop");

    // Stop monitoring immediately
    stopLocationMonitoring();

    // Clear in-memory data immediately
    _startVisit = null;
    _visitLocation = null;
    _visitImagePath = null;
    _visitAutoLogged = false;
    _startLocationAccuracy = null;
    _isNewShop = false; // NEW: Reset flag

    AppLogger.debug("🧹 Starting to clear SharedPreferences...");

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStartVisit);
    await prefs.remove(_keyLatitude);
    await prefs.remove(_keyLongitude);
    await prefs.remove(_keyImagePath);
    await prefs.remove(_keyAccuracy);
    await prefs.remove(_keyIsNewShop); // NEW

    AppLogger.debug("✅ Visit data cleared completely");
    notifyListeners();
  }

  @override
  void dispose() {
    AppLogger.debug("🔴 VisitProvider disposing");
    stopLocationMonitoring();
    super.dispose();
  }
}