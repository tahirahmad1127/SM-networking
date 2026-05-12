import 'package:flutter/material.dart';
import '../../../../configurations/frontend_configs.dart';
import '../../../../configurations/translation_helper.dart';
import 'tab_bars/processed_tab_bar.dart';
import 'tab_bars/cancelled_tab_bar.dart';
import 'tab_bars/completed_tab_bar.dart';
import 'tab_bars/in_progress_tab_bar.dart';

class OrderBody extends StatelessWidget {
  const OrderBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FrontendConfigs.appDivider,
            const SizedBox(
              height: 10,
            ),
            Container(
              height: 50,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                // color: FrontendConfigs.kGreyColor.withOpacity(0.4)
              ),
              child: Column(
                children: [
              Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: FrontendConfigs.kAppBorder,
                  color: FrontendConfigs.kTextFieldColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                  child: TabBar(
                    // Make tabs fill the full width equally
                    isScrollable: false,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorColor: FrontendConfigs.kPrimaryColor,
                    dividerColor: Colors.transparent,
                    labelColor: FrontendConfigs.kPrimaryColor,
                    unselectedLabelColor: Colors.black,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white, // active tab background color
                    ),
                    labelStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: FrontendConfigs.kPrimaryColor,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      Tab(text: TranslationHelper.getTranslatedText('pending')),
                      Tab(text: TranslationHelper.getTranslatedText('completed')),
                      Tab(text: TranslationHelper.getTranslatedText('cancelled')),
                    ],
                  ),
                ),
              ),
            )

          ],
              ),
            ),
            Expanded(
              child: TabBarView(children: [
                InProgressTabBar(),
                const CompletedTabBar(),
                const CancelledTabBar()
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
