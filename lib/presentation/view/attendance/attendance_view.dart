import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/injection_container.dart';

import '../../../application/checkIn_provider.dart';
import '../../../application/offline_mode_provider.dart';
import '../../../application/pending_recovery_provider.dart';
import '../../../application/pending_sync_provider.dart';
import 'package:provider/provider.dart';
import '../../../application/user_provider.dart';
import '../../elements/flush_bar.dart';
import '../pending_sync/pending_sync_view.dart';
import 'layout/body.dart';
import '../../../application/attendance_bloc/attendance_bloc.dart';
import '../../../application/tracking_bloc/tracking_bloc.dart';
import 'layout/warehouse_attendence_body.dart';

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  @override
  void initState() {
    super.initState();
    // PendingSyncProvider/PendingRecoveryProvider are registered globally in
    // main.dart, so they're already available here via Provider.of — just
    // trigger an initial load.
    Provider.of<PendingSyncProvider>(context, listen: false).load();
    Provider.of<PendingRecoveryProvider>(context, listen: false).load();
  }

  Future<void> _openSyncScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PendingSyncView()),
    );
    // Refresh the badge count in case orders/recoveries were synced/deleted there.
    if (mounted) {
      Provider.of<PendingSyncProvider>(context, listen: false).load();
      Provider.of<PendingRecoveryProvider>(context, listen: false).load();
    }
  }

  Future<void> _toggleOfflineMode(BuildContext context) async {
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
            title: const Text("Turn off Offline Mode?"),
            content: Text(
                "You have $pendingOrders order${pendingOrders == 1 ? '' : 's'} and "
                "$pendingRecoveries recover${pendingRecoveries == 1 ? 'y' : 'ies'} waiting to sync. "
                "They'll stay queued and sync when you tap Sync."),
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
      if (mounted) {
        getFlushBar(context, title: "Offline Mode turned off.");
      }
      return;
    }

    final isCheckedIn =
        Provider.of<CheckInProvider>(context, listen: false).isCheckedIn;
    if (!isCheckedIn) {
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
            "for offline use. Make sure you have a good internet connection."),
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
      if (mounted) {
        getFlushBar(context, title: "Could not load your session details.");
      }
      return;
    }

    final success = await offlineMode.enableOfflineMode(userDetails);
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AttendanceBloc>()),
        BlocProvider(create: (_) => sl<TrackingBloc>()),
      ],
      child: Builder(
        builder: (context) {
          final role = Provider.of<UserProvider>(context, listen: false)
                  .getSalesUserDetails()
                  ?.role ??
              '';
          final isWarehouseManager = role == 'warehouseManager';

          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            body: Stack(
              children: [
                isWarehouseManager
                    ? const WarehouseAttendanceBody()
                    : const AttendanceBody(),
                Positioned(
                  left: 16,
                  bottom: isWarehouseManager ? 16 : 126,
                  child: Consumer<OfflineModeProvider>(
                    builder: (context, offlineMode, _) {
                      return FloatingActionButton.extended(
                        heroTag: 'offlineModeFab',
                        onPressed: offlineMode.isCaching
                            ? null
                            : () => _toggleOfflineMode(context),
                        backgroundColor: offlineMode.isOffline
                            ? Colors.green.shade600
                            : Colors.grey.shade700,
                        icon: offlineMode.isCaching
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(
                                offlineMode.isOffline
                                    ? Icons.cloud_done
                                    : Icons.cloud_off,
                                color: Colors.white,
                              ),
                        label: Text(
                          offlineMode.isCaching
                              ? "Preparing..."
                              : offlineMode.isOffline
                                  ? "Offline: ON"
                                  : "Offline Mode",
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            floatingActionButton: Padding(
              padding: EdgeInsets.only(bottom: isWarehouseManager ? 0 : 110),
              child: Consumer2<PendingSyncProvider, PendingRecoveryProvider>(
                builder: (context, provider, recoveryProvider, _) {
                  final combinedCount = provider.count + recoveryProvider.count;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      FloatingActionButton.extended(
                        onPressed: () => _openSyncScreen(context),
                        backgroundColor: FrontendConfigs.kPrimaryColor,
                        icon: const Icon(Icons.sync, color: Colors.white),
                        label: const Text(
                          "Sync",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (combinedCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 22, minHeight: 22),
                            child: Center(
                              child: Text(
                                combinedCount > 99
                                    ? '99+'
                                    : '$combinedCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
