// lib/infrastructure/services/permission_helper.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionHelper {
  /// Request all necessary permissions for background location tracking
  static Future<bool> requestBackgroundLocationPermission(BuildContext context) async {
    try {
      // ✅ Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          await _showSimpleDialog(
            context,
            "Location Services Disabled",
            "Please enable location services to track attendance.",
          );
        }
        return false;
      }

      // ✅ Check current permissions
      var locationStatus = await Permission.location.status;
      var bgLocationStatus = await Permission.locationAlways.status;

      // ✅ If both already granted, return true
      if (locationStatus.isGranted && bgLocationStatus.isGranted) {
        debugPrint("✅ All permissions already granted");
        return true;
      }

      // ✅ Show ONE dialog explaining why we need permissions
      if (context.mounted) {
        final shouldRequest = await _showPermissionExplanation(context);
        if (!shouldRequest) return false;
      }

      // ✅ Request foreground location first
      if (!locationStatus.isGranted) {
        locationStatus = await Permission.location.request();
      }

      if (!locationStatus.isGranted) {
        debugPrint("⚠️ Foreground location not granted");
        if (context.mounted) {
          await _showSimpleDialog(
            context,
            "Permission Required",
            "Location permission is required to track attendance.",
          );
        }
        return false;
      }

      // ✅ Request background location
      if (!bgLocationStatus.isGranted) {
        bgLocationStatus = await Permission.locationAlways.request();
      }

      if (!bgLocationStatus.isGranted) {
        debugPrint("⚠️ Background location not granted");
        if (context.mounted) {
          await _showSimpleDialog(
            context,
            "Background Permission Required",
            "Please allow 'All the time' location access for accurate attendance tracking.",
          );
        }
        return false;
      }

      debugPrint("✅ All permissions granted - Location: ${locationStatus.isGranted}, Background: ${bgLocationStatus.isGranted}");
      return true;

    } catch (e) {
      debugPrint("❌ Error requesting permissions: $e");
      return false;
    }
  }

  /// Show ONE explanation dialog before requesting all permissions
  static Future<bool> _showPermissionExplanation(BuildContext context) async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text(
            "Location Permission Required",
            style: TextStyle(color: Colors.green[900]),
          ),
          content: const Text(
            "To track your attendance accurately, this app needs to access your location even when the app is closed.\n\n"
                "Please select 'Allow all the time' when prompted.",
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("Cancel"),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text("Continue"),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Show simple information dialog
  static Future<void> _showSimpleDialog(
      BuildContext context,
      String title,
      String message,
      ) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  /// Check if all required permissions are granted
  static Future<bool> hasAllPermissions() async {
    final location = await Permission.location.isGranted;
    final bgLocation = await Permission.locationAlways.isGranted;

    debugPrint("📋 Location: $location | Background: $bgLocation");

    return location && bgLocation;
  }

  /// Check current permission status
  static Future<Map<String, bool>> checkPermissionStatus() async {
    return {
      'location': await Permission.location.isGranted,
      'locationAlways': await Permission.locationAlways.isGranted,
    };
  }
}