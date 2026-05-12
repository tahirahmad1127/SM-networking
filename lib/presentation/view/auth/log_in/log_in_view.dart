import 'package:flutter/material.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/view/auth/log_in/layout/body.dart';

import '../../../elements/app_button.dart';
import '../widgets/auth_button.dart';

class LogInView extends StatelessWidget {
  const LogInView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: LogInBody(),
    );
  }
}
