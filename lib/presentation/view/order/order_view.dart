import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';

import '../../../configurations/translation_helper.dart';
import '../../elements/custom_appbar.dart';
import 'layout/body.dart';

class OrderView extends StatelessWidget {
  const OrderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          TranslationHelper.getTranslatedText('order'),
          style: FrontendConfigs.kSubHeadingStyle,
        ),
      ),
      body: const OrderBody(),
    );
  }
}
