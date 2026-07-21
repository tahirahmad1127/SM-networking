// lib/presentation/elements/sync_actions.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/checkIn_provider.dart';
import '../../application/offline_mode_provider.dart';
import '../../application/pending_recovery_provider.dart';
import '../../application/pending_sync_provider.dart';
import '../../application/user_provider.dart';
import '../view/pending_sync/pending_sync_view.dart';
import 'flush_bar.dart';

/// "Sync Up" — opens the Pending Sync screen (orders + recoveries queued
/// locally, either from Offline Mode or a dropped connection). Shared logic
/// so the Profile screen's "Sync Up" tile behaves identically to the old
/// Attendance-screen FAB it replaced.
Future<void> openSyncScreen(BuildContext context) async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PendingSyncView()),
  );
  // Refresh the badge count in case orders/recoveries were synced/deleted there.
  if (!context.mounted) return;
  Provider.of<PendingSyncProvider>(context, listen: false).load();
  Provider.of<PendingRecoveryProvider>(context, listen: false).load();
}

/// "Sync Down" — enables/disables Offline Mode. Shared logic so the Profile
/// screen's "Sync Down" tile behaves identically to the old Attendance-
/// screen FAB it replaced.
Future<void> toggleOfflineMode(BuildContext context) async {
  final offlineMode = Provider.of<OfflineModeProvider>(context, listen: false);

  if (offlineMode.isOffline) {
    final pendingOrders =
        Provider.of<PendingSyncProvider>(context, listen: false).count;
    final pendingRecoveries =
        Provider.of<PendingRecoveryProvider>(context, listen: false).count;
    final pendingCount = pendingOrders + pendingRecoveries;
    if (pendingCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Turn off Sync Down?"),
          content: Text(
              "You have $pendingOrders order${pendingOrders == 1 ? '' : 's'} and "
              "$pendingRecoveries recover${pendingRecoveries == 1 ? 'y' : 'ies'} waiting to sync. "
              "They'll stay queued and sync when you tap Sync Up."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Turn Off"),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await offlineMode.disableOfflineMode();
    if (context.mounted) {
      getFlushBar(context, title: "Offline Mode turned off.");
    }
    return;
  }

  final checkInProvider = Provider.of<CheckInProvider>(context, listen: false);
  // Force a fresh read from SharedPreferences (bypasses the cached in-memory
  // flag) before gating on check-in state. Right after an app restart,
  // CheckInProvider's in-memory flag starts at its `false` default and only
  // gets synced from disk once the Attendance screen's own loadStatus() call
  // resolves — a brief window where this check could spuriously say "not
  // checked in" even though the persisted state says otherwise.
  await checkInProvider.forceReload();
  if (!context.mounted) return;
  if (!checkInProvider.isCheckedIn) {
    getFlushBar(context,
        title: "You must be checked in to enable Offline Mode.");
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Enable Offline Mode?"),
      content: const Text(
          "This will download retailers, wholesalers, distributors, and products "
          "for offline use. Make sure you have a good internet connection.\n\n"
          "یہ ریٹیلرز، ہول سیلرز، ڈسٹری بیوٹرز اور پروڈکٹس کو آف لائن استعمال کے لیے "
          "ڈاؤن لوڈ کرے گا۔ براہ کرم ایک اچھا انٹرنیٹ کنکشن یقینی بنائیں۔"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Enable"),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  final userDetails =
      Provider.of<UserProvider>(context, listen: false).getSalesUserDetails();
  if (userDetails == null) {
    if (context.mounted) {
      getFlushBar(context, title: "Could not load your session details.");
    }
    return;
  }

  final success = await offlineMode.enableOfflineMode(userDetails);
  if (!context.mounted) return;
  if (success) {
    getFlushBar(
      context,
      title: offlineMode.cacheError != null
          ? "Offline Mode enabled. ${offlineMode.cacheError}"
          : "Offline Mode enabled — data cached for offline use.",
    );
  } else {
    getFlushBar(
      context,
      title: offlineMode.cacheError ?? "Could not enable Offline Mode.",
    );
  }
}
