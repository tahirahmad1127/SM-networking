import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../application/tracking_bloc/tracking_bloc.dart';
import '../../presentation/elements/flush_bar.dart';
import '../../presentation/elements/my_logger.dart';
import '../../presentation/elements/navigation_dialog.dart';
import '../model/location_tracking.dart';
import '../model/tracking.dart';
import 'google_place.dart';

class LocationService {
  static StreamSubscription<Position>? _userLiveTrackingStream;

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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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
      message: "Location permission is permanently denied.\nPlease enable it from settings.",
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

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      AppLogger.debug('Error getting LatLng: $e');
      return null;
    }
  }

  /// USER LIVE LOCATION TRACKING
  static Future<void> startUserLiveTracking({required BuildContext context, required String userId, int distanceFilterMeters = 5, TrackingBloc? trackingBloc,}) async {
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

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

      AppLogger.debug("User live location Tracking Started");

      // Firebase live stream
      _userLiveTrackingStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
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
          await FirebaseFirestore.instance
              .collection("LocationCollection")
              .doc(userId)
              .set(locationModel.toMap(), SetOptions(merge: true));
        } catch (e) {
          AppLogger.debug("Firebase update failed: $e");
        }
      });

      // Periodic API tracking (every 4 min)
      if (trackingBloc != null) {
        trackingBloc.add(
          StartTrackingEvent(
            intervalMinutes: 3,
            getCoordinatesBody: () async {
              // Get fresh position ----
              final Position position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
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
        AppLogger.debug("Warning: TrackingBloc not provided. API tracking skipped.");
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