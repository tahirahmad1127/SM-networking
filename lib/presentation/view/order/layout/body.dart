import 'package:flutter/material.dart';
import 'package:sm_networking/presentation/view/order/layout/tab_bars/draft_tabbar.dart';
import '../../../../configurations/frontend_configs.dart';
import '../../../../configurations/translation_helper.dart';
import 'tab_bars/processed_tab_bar.dart';
import 'tab_bars/cancelled_tab_bar.dart';
import 'tab_bars/completed_tab_bar.dart';
import 'tab_bars/in_progress_tab_bar.dart';

class OrderBody extends StatefulWidget {
  const OrderBody({super.key});

  @override
  State<OrderBody> createState() => _OrderBodyState();
}

class _OrderBodyState extends State<OrderBody> {
  final _draftsKey = GlobalKey<DraftsTabBarState>();
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tc = DefaultTabController.maybeOf(context);
    if (tc != null) {
      tc.addListener(_onTabChanged);
    }
  }

  void _onTabChanged() {
    final tc = DefaultTabController.maybeOf(context);
    if (tc?.index == 3) {
      _draftsKey.currentState?.reload();
    }
  }

  @override
  void dispose() {
    DefaultTabController.maybeOf(context)?.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 4,
        child: Builder(
          builder: (context) {
            // Attach listener after DefaultTabController is in tree
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final tc = DefaultTabController.maybeOf(context);
              tc?.removeListener(_onTabChanged);
              tc?.addListener(_onTabChanged);
            });
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FrontendConfigs.appDivider,
                const SizedBox(height: 10),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 5),
                      child: TabBar(
                        isScrollable: false,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorColor: FrontendConfigs.kPrimaryColor,
                        dividerColor: Colors.transparent,
                        labelColor: FrontendConfigs.kPrimaryColor,
                        unselectedLabelColor: Colors.black,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: [
                          Tab(text: TranslationHelper.getTranslatedText('pending')),
                          Tab(text: TranslationHelper.getTranslatedText('completed')),
                          Tab(text: TranslationHelper.getTranslatedText('cancelled')),
                          const Tab(text: 'Drafts'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TabBarView(children: [
                    InProgressTabBar(),
                    const CompletedTabBar(),
                    const CancelledTabBar(),
                    DraftsTabBar(key: _draftsKey),
                  ]),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}