import 'package:flutter/material.dart';

import '../../../infrastructure/model/maintenance.dart';
import '../../../infrastructure/services/maintenance.dart';
import 'maintenance_view.dart';

/// Wraps the whole app (see main.dart). Swaps out [child] for
/// [MaintenanceView] the instant appConfig/maintenance's
/// `isUnderMaintenance` flag goes true — and swaps back the instant it goes
/// false — since it's a live Firestore stream, not a one-time check at
/// startup. Any already-open screen gets interrupted, which is intentional:
/// if the backend is genuinely down, leaving people in a half-working app
/// (failed requests everywhere) is worse than a clear "come back later".
class MaintenanceGate extends StatefulWidget {
  final Widget child;

  const MaintenanceGate({super.key, required this.child});

  @override
  State<MaintenanceGate> createState() => _MaintenanceGateState();
}

class _MaintenanceGateState extends State<MaintenanceGate> {
  final _service = MaintenanceServices();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MaintenanceModel>(
      stream: _service.streamMaintenanceStatus(),
      builder: (context, snapshot) {
        final status = snapshot.data;
        if (status != null && status.isUnderMaintenance) {
          return MaintenanceView(title: status.title, message: status.message);
        }
        // No data yet (still connecting) or not under maintenance — never
        // block app entry on this check; fail open.
        return widget.child;
      },
    );
  }
}
