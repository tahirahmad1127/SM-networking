import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/translation_helper.dart';
import '../../../configurations/frontend_configs.dart';
import '../app_button.dart';
import '../custom_text.dart';

Future<void> changeLanguageSheet(context) {
  return showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    TranslationHelper.getTranslatedText("language"),
                    style: FrontendConfigs.kTitleStyle,
                  ),
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close))
                ],
              ),
            ),
            Divider(
              color: FrontendConfigs.kAuthTextColor,
              thickness: 0.2,
            ),
            const SizedBox(
              height: 12,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      // context.locale != const Locale('ur')
                      //     ? TranslationHelper.getTranslatedText(
                      //     "english")
                      //     : TranslationHelper.getTranslatedText("urdu");
                    },
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          borderRadius: FrontendConfigs.kAppBorder,
                          color:
                              FrontendConfigs.kPrimaryColor.withOpacity(0.2)),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 18.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: TranslationHelper.getTranslatedText(
                                  'english'),
                              color: FrontendConfigs.kPrimaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  InkWell(
                    onTap: () {},
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          borderRadius: FrontendConfigs.kAppBorder,
                          color: FrontendConfigs.kTextFieldColor),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 18.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: ' اردو',
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(
                          color: FrontendConfigs.kAuthTextColor, width: 0.5))),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppButton(
                      onPressed: () {},
                      btnLabel: TranslationHelper.getTranslatedText("cancel"),
                      width: MediaQuery.of(context).size.width / 2.25,
                      btnColor: const Color(0xff121212),
                    ),
                    AppButton(
                      onPressed: () {},
                      btnLabel: TranslationHelper.getTranslatedText("save"),
                      width: MediaQuery.of(context).size.width / 2.25,
                    )
                  ],
                ),
              ),
            ),
          ],
        );
      });
}
