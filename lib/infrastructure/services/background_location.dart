// lib/infrastructure/services/background_location_service.dart

import 'dart:async';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sm_networking/injection_container.dart' as di;
import 'package:sm_networking/infrastructure/services/tracking.dart';
import 'package:sm_networking/infrastructure/model/tracking.dart';
import 'package:sm_networking/infrastructure/model/location_tracking.dart';
import 'offline_location_queue.dart';


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

  static StreamSubscription<Position>? _gpsStreamSub;

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
      _gpsStreamSub?.cancel();
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

    // ── Real-time GPS stream ──────────────────────────────────────────────
    // Replaces the old one-shot getCurrentPosition polling. A continuous
    // GPS-only stream (forceLocationManager: true) keeps emitting real
    // fresh fixes even with no internet at all — getCurrentPosition with
    // the same flag is a known-broken combination on devices with Google
    // Play Services installed (the stream variant doesn't have that bug).
    // Every fix that comes through, online or offline, gets a Firestore
    // write attempt; failures are queued locally and replayed in order
    // once connectivity returns, so the real path is reconstructed rather
    // than a single frozen point.
    void startGpsStream() {
      _gpsStreamSub?.cancel();
      _gpsStreamSub = Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // meters — skip near-identical jitter
          forceLocationManager: true,
        ),
      ).listen(
            (position) async {
          final isCheckedIn = prefs.getBool('isCheckedIn') ?? false;
          if (!isCheckedIn) return;

          final userId = (prefs.getString('userId') ?? '').trim();
          if (userId.isEmpty) return;

          updateCount++;
          final now = DateTime.now();

          // Drain any backlog first, so a long offline period catches up
          // gradually as connectivity allows, oldest point first.
          await _flushOfflineQueue();

          final ok = await _updateFirebase(
              userId, position.latitude, position.longitude, at: now);

          if (!ok) {
            await OfflineLocationQueueService.add(
              OfflineLocationPing(
                userId: userId,
                latitude: position.latitude,
                longitude: position.longitude,
                timestamp: now,
              ),
            );
            log("📦 Offline — queued real GPS point for later sync "
                "(${position.latitude}, ${position.longitude})");
          } else {
            log("📍 Background Firebase update #$updateCount: "
                "${position.latitude}, ${position.longitude}");
          }
        },
        onError: (e) {
          log("⚠️ GPS stream error: $e — will retry");
        },
      );
    }

    startGpsStream();

    // Watchdog: if the service is checked-in but the stream died for any
    // reason (some Android versions can kill long-lived streams under
    // memory pressure), restart it. Also stops everything cleanly once
    // the user checks out.
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (service is AndroidServiceInstance) {
        if (!await service.isForegroundService()) return;
      }
      final isCheckedIn = prefs.getBool('isCheckedIn') ?? false;
      if (!isCheckedIn) {
        debugPrint("⚠️ User not checked in, stopping service");
        timer.cancel();
        _gpsStreamSub?.cancel();
        service.stopSelf();
        return;
      }
      if (_gpsStreamSub == null) {
        log("♻️ Restarting GPS stream after unexpected stop");
        startGpsStream();
      }
    });

    // API: Send coordinates every 3 minutes (separate from Firestore —
    // this is the periodic backend ping, unrelated to the live map feed).
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

            final position = await _getCurrentPositionForApi();
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

  /// One-shot position fetch used only for the periodic backend API ping
  /// (every 3 minutes) — separate from the continuous GPS stream that
  /// drives the Firestore live-map feed. Falls back to the last known
  /// position if a fresh fix isn't available quickly.
  static Future<Position?> _getCurrentPositionForApi() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        log("⚠️ Location permission denied");
        return null;
      }

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      } on TimeoutException {
        log("⚠️ Fused provider timed out for API ping — using last known position");
      }

      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      log("❌ Error getting position for API ping: $e");
      return null;
    }
  }

  // Update Firebase (real-time tracking). Writes both the single
  // "current location" doc (unchanged shape, so existing portal code that
  // reads it keeps working) and a timestamped entry in a history
  // sub-collection, so a path can be reconstructed later. Returns true on
  // success, false if the write failed (caller queues it locally instead).
  static Future<bool> _updateFirebase(
      String userId,
      double latitude,
      double longitude, {
        DateTime? at,
        bool wasOffline = false,
      }) async {
    try {
      final now = at ?? DateTime.now();
      final locationModel = LocationTrackingModel(
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        createdAt: now,
        updatedAt: now,
      );

      final userDoc =
      FirebaseFirestore.instance.collection("LocationCollection").doc(userId);

      final batch = FirebaseFirestore.instance.batch();
      batch.set(userDoc, locationModel.toMap(), SetOptions(merge: true));
      batch.set(userDoc.collection('history').doc(), {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': now.toIso8601String(),
        'wasOffline': wasOffline,
      });
      await batch.commit();

      log("✅ Firebase updated successfully");
      return true;
    } catch (e) {
      log("❌ Firebase update failed: $e");
      return false;
    }
  }

  /// Attempts to drain the offline queue, oldest-first, in small batches
  /// so a long offline period catches up gradually rather than risking
  /// one huge failed write the moment connectivity returns.
  static Future<void> _flushOfflineQueue() async {
    const int maxPerTick = 25;
    final pending = await OfflineLocationQueueService.getAll();
    if (pending.isEmpty) return;

    final batch = pending.take(maxPerTick).toList();
    int succeeded = 0;
    for (final ping in batch) {
      final ok = await _updateFirebase(
        ping.userId,
        ping.latitude,
        ping.longitude,
        at: ping.timestamp,
        wasOffline: true,
      );
      if (ok) {
        succeeded++;
      } else {
        // Stop at the first failure — connectivity likely dropped again
        // mid-flush. Whatever succeeded so far is removed below; the rest
        // stays queued for the next tick.
        break;
      }
    }

    if (succeeded > 0) {
      await OfflineLocationQueueService.removeOldest(succeeded);
      log("📤 Flushed $succeeded queued offline location ping(s)"
          "${pending.length > succeeded ? ' (${pending.length - succeeded} still queued)' : ''}");
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