import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/translation_helper.dart';

import '../../../configurations/frontend_configs.dart';
import 'layout/body.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          TranslationHelper.getTranslatedText('profile'),
          style: FrontendConfigs.kSubHeadingStyle,
        ),
      ),
      body: const ProfileBody(),
    );
  }
}
