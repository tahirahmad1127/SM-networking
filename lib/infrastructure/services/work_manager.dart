// lib/infrastructure/services/workmanager_service.dart

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:sm_networking/injection_container.dart' as di;
import 'location.dart';
import 'attendance.dart';

/// CRITICAL: This runs in a separate isolate → must re-init GetIt!
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      debugPrint("WorkManager task started: $task");

      // RE-INITIALIZE GetIt in background isolate
      await di.init();

      final prefs = await SharedPreferences.getInstance();
      final isCheckedIn = prefs.getBool('isCheckedIn') ?? false;
      if (!isCheckedIn) {
        debugPrint("User not checked in → skipping task");
        return true;
      }

      final now = DateTime.now();
      final allowedTimeStr =
          prefs.getString('ALLOWED_CHECKOUT_TIME') ?? '17:00';
      final checkoutTime = _parseTimeToday(allowedTimeStr) ??
          DateTime(now.year, now.month, now.day, 17, 0);

      final formattedCheckoutTime = DateFormat('hh:mm a').format(checkoutTime);

      // 30-minute reminder
      if (task == 'reminder_30') {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 430,
            channelKey: 'basic_channel',
            title: '30 Minutes Left',
            body: 'Auto checkout at $formattedCheckoutTime. Wrap up your work!',
            wakeUpScreen: true,
            criticalAlert: true,
          ),
        );
        return true;
      }

      // 15-minute reminder
      if (task == 'reminder_15') {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 445,
            channelKey: 'basic_channel',
            title: '15 Minutes Left',
            body: 'Auto-checkout soon at $formattedCheckoutTime!',
            wakeUpScreen: true,
            criticalAlert: true,
          ),
        );
        return true;
      }

      // AUTO CHECKOUT
      if (task == 'auto_checkout') {
        final isCheckedIn = prefs.getBool('isCheckedIn') ?? false;
        final hasCheckoutTime = prefs.getString('CHECK_OUT_TIME') != null;

        if (!isCheckedIn || hasCheckoutTime) {
          debugPrint(
              "Already checked out or not checked in → skipping auto-checkout");
          return true;
        }

        if (now.isBefore(checkoutTime)) {
          debugPrint("Not time yet. Current: $now, Target: $checkoutTime");
          return true;
        }

        final formattedNow = DateFormat('hh:mm a').format(now);
        final isoNow = now.toIso8601String();

        debugPrint("⚡ AUTO CHECKOUT EXECUTING at $formattedNow");

        // Notification
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: 999,
            channelKey: 'basic_channel',
            title: 'Auto Checked Out',
            body: 'You were automatically checked out at $formattedNow',
            wakeUpScreen: true,
            criticalAlert: true,
          ),
        );

        // Sync with server
        final attendanceId = prefs.getString('attendanceId');
        if (attendanceId != null) {
          try {
            final repo = di.sl<AttendanceRepositoryImp>();

            // Create the body properly
            final body = {
              'checkOutTime': isoNow,
            };

            debugPrint("🔵 Calling checkOut API with body: $body");

            final result = await repo.checkOut(attendanceId, body);

            result.fold(
              (error) {
                debugPrint("❌ Failed to sync auto-checkout: ${error.error}");
                // Save for retry later
                prefs.setString('pending_checkout', attendanceId);
                prefs.setString('pending_checkout_time', isoNow);
              },
              (success) {
                debugPrint("✅ Auto-checkout synced to server successfully");
                // CRITICAL: Update SharedPreferences AFTER successful API call
                prefs.setBool('isCheckedIn', false);
                prefs.setString('CHECK_OUT_TIME', isoNow);
                prefs.setString('lastAutoCheckout', isoNow);
                prefs.setString('autoCheckoutTimestamp', isoNow);
              },
            );
          } catch (e) {
            debugPrint("❌ Exception during auto-checkout sync: $e");
            await prefs.setString('pending_checkout', attendanceId);
            await prefs.setString('pending_checkout_time', isoNow);
          }
        }

        try {
          await LocationService.stopUserLiveTracking();

          // Stop background service
          final service = FlutterBackgroundService();
          service.invoke("stopService");

          debugPrint("✅ All tracking stopped");
        } catch (e) {
          debugPrint("⚠️ Failed to stop tracking: $e");
        }

        return true;
      }

      // AUTO CHECKOUT
      // if (task == 'auto_checkout') {
      //   final isCheckedIn = prefs.getBool('isCheckedIn') ?? false;
      //   final hasCheckoutTime = prefs.getString('CHECK_OUT_TIME') != null;
      //
      //   if (!isCheckedIn || hasCheckoutTime) {
      //     debugPrint("Already checked out or not checked in → skipping auto-checkout");
      //     return true;
      //   }
      //
      //   if (now.isBefore(checkoutTime)) {
      //     debugPrint("Not time yet. Current: $now, Target: $checkoutTime");
      //     return true;
      //   }
      //
      //   final formattedNow = DateFormat('hh:mm a').format(now);
      //   final isoNow = now.toIso8601String();
      //
      //   debugPrint("⚡ AUTO CHECKOUT EXECUTING at $formattedNow");
      //
      //   // CRITICAL: Update SharedPreferences FIRST
      //   await prefs.setBool('isCheckedIn', false);
      //   await prefs.setString('CHECK_OUT_TIME', isoNow);
      //   await prefs.setString('lastAutoCheckout', isoNow);
      //   await prefs.setString('autoCheckoutTimestamp', isoNow);
      //
      //   debugPrint("✅ SharedPreferences updated: isCheckedIn=false");
      //
      //   // Notification
      //   await AwesomeNotifications().createNotification(
      //     content: NotificationContent(
      //       id: 999,
      //       channelKey: 'basic_channel',
      //       title: 'Auto Checked Out',
      //       body: 'You were automatically checked out at $formattedNow',
      //       wakeUpScreen: true,
      //       criticalAlert: true,
      //     ),
      //   );
      //
      //   // Sync with server
      //   final attendanceId = prefs.getString('attendanceId');
      //   if (attendanceId != null) {
      //     try {
      //       final repo = di.sl<AttendanceRepositoryImp>();
      //       final result = await repo.checkOut(attendanceId, AttendanceModel(checkOutTime: isoNow).toJson());
      //
      //       result.fold(
      //             (error) {
      //           debugPrint("❌ Failed to sync auto-checkout: ${error.error}");
      //           // Save for retry later
      //           prefs.setString('pending_checkout', attendanceId);
      //           prefs.setString('pending_checkout_time', isoNow);
      //         },
      //             (success) {
      //           debugPrint("✅ Auto-checkout synced to server successfully");
      //         },
      //       );
      //     } catch (e) {
      //       debugPrint("❌ Exception during auto-checkout sync: $e");
      //       await prefs.setString('pending_checkout', attendanceId);
      //       await prefs.setString('pending_checkout_time', isoNow);
      //     }
      //   }
      //
      //   try {
      //     await LocationService.stopUserLiveTracking();
      //     debugPrint("✅ Location tracking stopped");
      //   } catch (e) {
      //     debugPrint("⚠️ Failed to stop location tracking: $e");
      //   }
      //
      //   return true;
      // }

      return true;
    } catch (e, stack) {
      debugPrint("WorkManager crashed: $e\n$stack");
      return false;
    }
  });
}

/// Parse "17:00" → DateTime for today
DateTime? _parseTimeToday(String? timeStr) {
  if (timeStr == null) return null;
  try {
    final parts = timeStr.split(':');
    if (parts.length < 2) return null;
    final hour = int.parse(parts[0]);
    final minute =
        int.parse(parts[1].split(' ').first); // in case of "17:00 PKT"
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  } catch (e) {
    debugPrint("Failed to parse time: $timeStr");
    return null;
  }
}
