import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sm_networking/configurations/translation_helper.dart';

import '../../../configurations/frontend_configs.dart';
import '../../elements/custom_appbar.dart';
import '../../elements/custom_text.dart';
import 'layout/body.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

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