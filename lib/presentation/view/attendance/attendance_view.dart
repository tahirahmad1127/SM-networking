import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/injection_container.dart';

import 'package:provider/provider.dart';
import '../../../application/user_provider.dart';
import 'layout/body.dart';
import '../../../application/attendance_bloc/attendance_bloc.dart';
import '../../../application/tracking_bloc/tracking_bloc.dart';
import 'layout/warehouse_attendence_body.dart';

class AttendanceView extends StatelessWidget {
  const AttendanceView({super.key});

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
            body: isWarehouseManager
                ? const WarehouseAttendanceBody()
                : const AttendanceBody(),
          );
        },
      ),
    );
  }
}
