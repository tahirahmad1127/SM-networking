import 'package:flutter/material.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';

import 'layout/body.dart';

class TermsConditionView extends StatelessWidget {
  const TermsConditionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, text: "Terms & Conditions", showText: true),
      body: TermsConditionViewBody(),
    );
  }
}
