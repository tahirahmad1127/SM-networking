import 'package:flutter/material.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/view/check_out/layout/body.dart';

class CheckOutView extends StatelessWidget {
  const CheckOutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context),
      body: const CheckOutBody(),
    );
  }
}
