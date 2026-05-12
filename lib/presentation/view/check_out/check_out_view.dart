import 'package:flutter/material.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/view/check_out/layout/body.dart';
import 'package:sm_networking/presentation/view/order/order_placed_view.dart';
import 'package:provider/provider.dart';

import '../../../configurations/frontend_configs.dart';
import '../../elements/app_button.dart';
import '../../elements/custom_text.dart';

class CheckOutView extends StatelessWidget {
  const CheckOutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context),

      body: const CheckOutBody(
      ),
    );
  }
}
