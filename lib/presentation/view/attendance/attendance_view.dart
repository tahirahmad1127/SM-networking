import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/injection_container.dart';

import '../../../application/pending_sync_provider.dart';
import '../../../configurations/translation_helper.dart';
import 'package:provider/provider.dart';
import '../../../application/user_provider.dart';
import '../../elements/custom_text.dart';
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
    // PendingSyncProvider is registered globally in main.dart, so it's
    // already available here via Provider.of — just trigger an initial load.
    Provider.of<PendingSyncProvider>(context, listen: false).load();
  }

  Future<void> _openSyncScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PendingSyncView()),
    );
    // Refresh the badge count in case orders were synced/deleted there.
    if (mounted) {
      Provider.of<PendingSyncProvider>(context, listen: false).load();
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
              .getSalesUserDetails()?.role ?? '';
          final isWarehouseManager = role == 'warehouseManager';

          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            body: isWarehouseManager
                ? const WarehouseAttendanceBody()
                : const AttendanceBody(),
            floatingActionButton: Padding(
              padding: EdgeInsets.only(bottom: isWarehouseManager ? 0 : 110),
              child: Consumer<PendingSyncProvider>(
                builder: (context, provider, _) {
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
                      if (provider.count > 0)
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
                                provider.count > 99 ? '99+' : '${provider.count}',
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