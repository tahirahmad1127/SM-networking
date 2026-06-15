// lib/infrastructure/services/background_location_service.dart

import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sm_networking/injection_container.dart' as di;
import 'package:sm_networking/infrastructure/services/tracking.dart';
import 'package:sm_networking/infrastructure/model/tracking.dart';
import 'package:sm_networking/infrastructure/model/location_tracking.dart';


@pragma('vm:entry-point')
class BackgroundLocationService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'location_tracking',
        initialNotificationTitle: 'Location Tracking Active',
        initialNotificationContent: 'Tracking your attendance location...',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    //  Initialize Firebase in background isolate
    try {
      await Firebase.initializeApp();
      log("✅ Firebase initialized in background service");
    } catch (e) {
      log("⚠️ Firebase initialization: $e");
    }

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });

      // SET STATIC NOTIFICATION (no updates)
      service.setForegroundNotificationInfo(
        title: "Location Tracking Active",
        content: "Tracking your attendance location in background",
      );
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Re-initialize GetIt in background isolate
    try {
      await di.init();
      log("✅ GetIt initialized in background service");
    } catch (e) {
      log("⚠️ GetIt initialization: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    int updateCount = 0;

    // FIREBASE: Update every 10 seconds (real-time)
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        if (service is AndroidServiceInstance) {
          if (await service.isForegroundService()) {
            final isCheckedIn = prefs.getBool('isCheckedIn') ?? false;

            if (!isCheckedIn) {
              debugPrint("⚠️ User not checked in, stopping service");
              timer.cancel();
              service.stopSelf();
              return;
            }

            // FIX: fall back to 'salesUserId' so TSM/orderBooker users
            // whose id is stored under a different prefs key are found.
            final userId = (prefs.getString('userId') ?? '').trim();
            if (userId.isEmpty) {
              debugPrint("⚠️ No userId found in prefs — location ping skipped");
              return;
            }

            final position = await _getCurrentPosition();
            if (position != null) {
              updateCount++;

              // UPDATE FIREBASE (every 10 seconds)
              await _updateFirebase(userId, position);

              log("📍 Background Firebase update #$updateCount: ${position.latitude}, ${position.longitude}");
            }
          }
        }
      } catch (e, s) {
        debugPrint("❌ Firebase tracking error: $e\n$s");
      }
    });

    // API: Send coordinates every 3 minutes
    Timer.periodic(const Duration(minutes: 3), (timer) async {
      try {
        if (service is AndroidServiceInstance) {
          if (await service.isForegroundService()) {
            final isCheckedIn = prefs.getBool('isCheckedIn') ?? false;

            if (!isCheckedIn) {
              timer.cancel();
              return;
            }

            final userId = (prefs.getString('userId') ?? '').trim();
            if (userId.isEmpty) return;

            final position = await _getCurrentPosition();
            if (position != null) {
              await _sendToAPI(userId, position);
            }
          }
        }
      } catch (e, s) {
        log("❌ API tracking error: $e\n$s");
      }
    });
  }

  static Future<Position?> _getCurrentPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        log("⚠️ Location permission denied");
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      log("❌ Error getting position: $e");
      return null;
    }
  }

  // Update Firebase (real-time tracking)
  static Future<void> _updateFirebase(String userId, Position position) async {
    try {
      final now = DateTime.now();
      final locationModel = LocationTrackingModel(
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
        createdAt: now,
        updatedAt: now,
      );

      await FirebaseFirestore.instance
          .collection("LocationCollection")
          .doc(userId)
          .set(locationModel.toMap(), SetOptions(merge: true));

      log("✅ Firebase updated successfully");
    } catch (e) {
      log("❌ Firebase update failed: $e");
    }
  }

  // Send to API (periodic tracking)
  static Future<void> _sendToAPI(String userId, Position position) async {
    try {
      final repo = di.sl<TrackingRepositoryImp>();

      final isoDate = DateTime.now()
          .toUtc()
          .toIso8601String()
          .split('.')
          .first;

      final body = TrackingRequestModel(
        salesPersonID: userId,
        lat: position.latitude,
        lng: position.longitude,
        date: isoDate,
      ).toJson();

      log("📦 Sending to API: $body");

      final result = await repo.sendCoordinates(body);

      result.fold(
            (error) => log("❌ API tracking failed: ${error.error}"),
            (success) => log("✅ API tracking success: ${success.msg}"),
      );
    } catch (e, s) {
      log("❌ Exception sending to API: $e\n$s");
    }
  }

  // ── Start the background service ──────────────────────────────────────────
  // Call this at check-in time, passing the logged-in user's id.
  // The id is persisted to SharedPreferences so the background isolate
  // (which has no Provider access) can read it on every tick.
  static Future<void> startTracking(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);

      final service = FlutterBackgroundService();

      final isRunning = await service.isRunning();
      if (!isRunning) {
        await service.startService();
        log("✅ Background service started for user: $userId");
      } else {
        log("ℹ️ Background service already running");
      }
    } catch (e) {
      debugPrint("❌ Error starting background service: $e");
    }
  }

  // ── Stop the background service ───────────────────────────────────────────
  static Future<void> stopTracking() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();

      if (isRunning) {
        service.invoke("stopService");
        log("🛑 Background service stopped");
      }
    } catch (e) {
      log("❌ Error stopping background service: $e");
    }
  }
}