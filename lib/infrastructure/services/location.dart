import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../application/tracking_bloc/tracking_bloc.dart';
import '../../presentation/elements/flush_bar.dart';
import '../../presentation/elements/my_logger.dart';
import '../../presentation/elements/navigation_dialog.dart';
import '../model/location_tracking.dart';
import '../model/tracking.dart';
import 'google_place.dart';
import 'offline_location_queue.dart';

class LocationService {
  static StreamSubscription<Position>? _userLiveTrackingStream;

  /// One-shot position fetch with an offline-resilient fallback: tries the
  /// default fused provider first (fast, accurate when online), and if it
  /// times out — which happens on Android when there's no internet, since
  /// the fused provider can depend on Google Play Services connectivity —
  /// retries once forcing the legacy LocationManager, which talks to the
  /// GPS hardware directly and works without internet.
  static Future<Position> _getPositionWithOfflineFallback({
    required Duration timeLimit,
  }) async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: timeLimit,
      );
    } on TimeoutException {
      log("⚠️ Fused provider timed out — retrying with GPS-only (LocationManager)");
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        forceAndroidLocationManager: true,
        timeLimit: timeLimit + const Duration(seconds: 5),
      );
    } on TimeoutException {
      log("⚠️ GPS-only fix also timed out — falling back to last known position");
    }

    // Final fallback: Android's cached last fix, returned near-instantly
    // with no fresh GPS lock or network required. This is effectively
    // what lets apps like Google Maps show a location dot offline almost
    // immediately, even when a brand-new fix is slow or unavailable.
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown == null) {
      // Nothing cached either — surface the original failure rather than
      // silently returning a fake/zero position.
      throw TimeoutException(
          'No position available: fresh fix timed out and no last known position is cached');
    }
    log("📍 Using last known position (age: "
        "${DateTime.now().difference(lastKnown.timestamp).inSeconds}s)");
    return lastKnown;
  }

  /// Get current location as address string
  static Future<String?> getCurrentLocationAddress(BuildContext context) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) return null;
      if (permission == LocationPermission.deniedForever) {
        return 'PERMISSION_DENIED_FOREVER';
      }

      final position = await _getPositionWithOfflineFallback(
        timeLimit: const Duration(seconds: 10),
      );

      final address = await GooglePlacesService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      return address;
    } catch (e) {
      AppLogger.debug('Error getting current location: $e');
      return null;
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    getFlushBar(context, title: message);
  }

  static Future<void> _showPermissionDialog(BuildContext context) async {
    await showNavigationDialog(
      context,
      message:
          "Location permission is permanently denied.\nPlease enable it from settings.",
      buttonText: "Open Settings",
      navigation: () => Geolocator.openAppSettings(),
      secondButtonText: "Cancel",
      showSecondButton: true,
    );
  }

  /// Get current LatLng
  static Future<LatLng?> getCurrentLatLng(BuildContext context) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) {
        await _showPermissionDialog(context);
        return null;
      }

      final position = await _getPositionWithOfflineFallback(
        timeLimit: const Duration(seconds: 30),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      AppLogger.debug('Error getting LatLng: $e');
      return null;
    }
  }

  /// USER LIVE LOCATION TRACKING
  static Future<void> startUserLiveTracking({
    required BuildContext context,
    required String userId,
    int distanceFilterMeters = 5,
    TrackingBloc? trackingBloc,
  }) async {
    try {
      // Permission & service checks (unchanged)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar(context, "Please enable location services");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar(context, "Location permission denied");
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        await _showPermissionDialog(context);
        return;
      }

      // Stop any previous tracking
      await stopUserLiveTracking(trackingBloc: trackingBloc);

      AppLogger.debug("User live location Tracking Started");

      // forceLocationManager bypasses the fused provider (which can
      // depend on Google Play Services connectivity and stall when
      // there's no internet) in favor of talking to the GPS hardware
      // directly — this is what keeps the stream alive offline.
      // Note: getPositionStream on this geolocator version requires
      // locationSettings (unlike getCurrentPosition, which still accepts
      // the old direct params), so AndroidSettings is used here.
      _userLiveTrackingStream = Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
          forceLocationManager: true,
        ),
      ).listen((Position position) async {
        final now = DateTime.now();

        final locationModel = LocationTrackingModel(
          userId: userId,
          latitude: position.latitude,
          longitude: position.longitude,
          createdAt: now,
          updatedAt: now,
        );

        log("Firebase update: ${position.latitude}, ${position.longitude}");
        log('Accuracy: ${position.accuracy} m');
        log('Speed: ${position.speed} m/s');

        try {
          final userDoc = FirebaseFirestore.instance
              .collection("LocationCollection")
              .doc(userId);

          final batch = FirebaseFirestore.instance.batch();
          batch.set(userDoc, locationModel.toMap(), SetOptions(merge: true));
          batch.set(userDoc.collection('history').doc(), {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': now.toIso8601String(),
            'wasOffline': false,
          });
          await batch.commit();
        } catch (e) {
          AppLogger.debug("Firebase update failed: $e");
          // No internet / Firestore unreachable — queue this ping locally.
          // The background service (running in parallel) periodically
          // drains this same queue once connectivity returns, so the
          // point isn't lost even if this foreground stream never
          // retries it itself.
          try {
            await OfflineLocationQueueService.add(
              OfflineLocationPing(
                userId: userId,
                latitude: position.latitude,
                longitude: position.longitude,
                timestamp: now,
              ),
            );
          } catch (queueError) {
            AppLogger.debug("Failed to queue offline ping: $queueError");
          }
        }
      });

      // Periodic API tracking (every 4 min)
      if (trackingBloc != null) {
        trackingBloc.add(
          StartTrackingEvent(
            intervalMinutes: 3,
            getCoordinatesBody: () async {
              // Get fresh position ----
              final Position position = await _getPositionWithOfflineFallback(
                timeLimit: const Duration(seconds: 15),
              );

              //  Build request body ----
              final String isoDate = DateTime.now()
                  .toUtc()
                  .toIso8601String()
                  .split('.')
                  .first; // e.g. "2025-11-07T12:34:56"

              final Map<String, dynamic> body = TrackingRequestModel(
                salesPersonID: userId,
                lat: position.latitude,
                lng: position.longitude,
                date: isoDate,
              ).toJson();

              // LOG THE PAYLOAD ----
              log("API payload (ready to send) → $body");

              return body;
            },
          ),
        );

        log("Started periodic API tracking (every 4 min) for user: $userId");
      } else {
        AppLogger.debug(
            "Warning: TrackingBloc not provided. API tracking skipped.");
      }

      AppLogger.debug("Started live tracking for user: $userId");
    } catch (e, s) {
      AppLogger.debug('Error starting live tracking: $e\n$s');
      _showSnackBar(context, "Failed to start live tracking");
    }
  }

  /// Stop live tracking (Firebase + BLoC)
  static Future<void> stopUserLiveTracking({TrackingBloc? trackingBloc}) async {
    // Cancel Firebase stream
    if (_userLiveTrackingStream != null) {
      await _userLiveTrackingStream!.cancel();
      _userLiveTrackingStream = null;
      AppLogger.debug("Stopped Firebase live tracking");
    }

    // Stop periodic API tracking
    trackingBloc?.add(const StopTrackingEvent());

    AppLogger.debug("Stopped user live tracking");
  }

  /// Check if live tracking is active
  static bool isUserLiveTrackingActive() {
    return _userLiveTrackingStream != null;
  }
}
