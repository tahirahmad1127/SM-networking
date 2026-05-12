import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/presentation/elements/app_button.dart';
import 'package:sm_networking/presentation/view/auth/log_in/log_in_view.dart';

import '../../../../../configurations/translation_helper.dart';
import '../../widgets/auth_button.dart';
import 'widgets/row_widget.dart';

class WelcomeBody extends StatelessWidget {
  const WelcomeBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 100,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 18.0),
            child: Image.asset(
              "assets/images/karyana_or.png",
              height: 44,
              width: 140,
            ),
          ),
          const SizedBox(
            height: 44,
          ),
          Expanded(
            child: Container(
              width: MediaQuery.of(context).size.width,
              color: Colors.white,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationHelper.getTranslatedText("welcome_to_karyana"),
                      style: FrontendConfigs.kHeadingStyle,
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    RowWidget(
                        logo: "assets/images/shopping_cart.png",
                        text: TranslationHelper.getTranslatedText(
                            "we_make_shopping")),
                    RowWidget(
                        logo: "assets/images/product_listening.png",
                        text: TranslationHelper.getTranslatedText(
                            "our_app_offer")),
                    RowWidget(
                        logo: "assets/images/ordering_system.png",
                        text: TranslationHelper.getTranslatedText(
                            "our_ordering_system")),
                    RowWidget(
                        logo: "assets/images/shops.png",
                        text: TranslationHelper.getTranslatedText(
                            "find_everything_you_need")),
                    RowWidget(
                        logo: "assets/images/online_shoping.png",
                        text: TranslationHelper.getTranslatedText(
                            "start_shopping_now")),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
