import 'package:flutter/material.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';

import 'layout/body.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, text: "Privacy Policy", showText: true),
      body: const PrivacyPolicyViewBody(),
    );
  }
}
