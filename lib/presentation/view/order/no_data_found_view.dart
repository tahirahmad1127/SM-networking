import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/configurations/translation_helper.dart';

class NoDataFoundView extends StatelessWidget {
  const NoDataFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          "assets/images/no_data.png",
          height: 180,
          width: 180,
        ),
        const SizedBox(
          height: 18,
        ),
        Text(
          TranslationHelper.getTranslatedText("no_data_found"),
          style: FrontendConfigs.kSubHeadingStyle,
        ),
        // const SizedBox(
        //   height: 10,
        // ),
        // CustomText(
        //   text: TranslationHelper.getTranslatedText("add_import_data"),
        //   fontSize: 18,
        //   fontWeight: FontWeight.w400,
        //   color: FrontendConfigs.kAuthTextColor,
        // )
      ],
    );
  }
}
