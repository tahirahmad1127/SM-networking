import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/injection_container.dart';

import '../../../configurations/translation_helper.dart';
import '../../elements/custom_text.dart';
import 'layout/body.dart';
import '../../../application/attendance_bloc/attendance_bloc.dart';
import '../../../application/tracking_bloc/tracking_bloc.dart';

class AttendanceView extends StatelessWidget {
  const AttendanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AttendanceBloc>()),
        BlocProvider(create: (_) => sl<TrackingBloc>()),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: const AttendanceBody(), // ← NOW SAFE!
      ),
    );
  }
}