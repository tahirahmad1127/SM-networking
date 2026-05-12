import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/application/cart_provider.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/order.dart';
import 'package:sm_networking/infrastructure/model/user.dart';
import 'package:sm_networking/infrastructure/services/order.dart';
import 'package:sm_networking/infrastructure/services/retailer.dart';
import 'package:sm_networking/infrastructure/services/transaction.dart';
import 'package:sm_networking/presentation/elements/app_button.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:sm_networking/presentation/view/cart/cart_view.dart';
import 'package:sm_networking/presentation/view/stats/layout/widget/yearly_chart.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../application/stats_bloc/stats_bloc.dart';
import '../../../../infrastructure/model/cart.dart';
import '../../../../infrastructure/model/stats.dart';
import '../../../../infrastructure/model/transaction.dart';
import '../../../../injection_container.dart';

class StatsViewBody extends StatefulWidget {
  const StatsViewBody({super.key});

  @override
  State<StatsViewBody> createState() => _StatsViewBodyState();
}

class _StatsViewBodyState extends State<StatsViewBody> {
  String dropdownvalue = '1-24 jun-2023';

  // List of items in our dropdown menu
  var items = [
    '1-24 jun-2023',
    'Item 2',
    'Item 3',
    'Item 4',
    'Item 5',
  ];

  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<UserProvider>(context);
    return BlocProvider(
      create: (context) => sl<StatsBloc>(),
      child: BlocBuilder<StatsBloc, StatsState>(
        builder: (context, state) {
          if (state is StatsLoading || state is StatsInitial) {
            BlocProvider.of<StatsBloc>(context).add(
                GetStatsEvent(user.getSalesUserDetails()!.user!.id.toString()));
            return Center(
              child: ProcessingWidget(),
            );
          } else if (state is StatsLoaded) {
            return SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 30,
                          ),
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 18.0),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: FrontendConfigs.kTextFieldColor),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: SizedBox(
                                      height: 42,
                                      child: TabBar(
                                          dividerColor:Colors.transparent,
                                          indicatorSize:TabBarIndicatorSize.tab,
                                          // indicatorColor: FrontendConfigs.kPrimaryColor,
                                          labelColor:
                                          FrontendConfigs.kPrimaryColor,
                                          onTap: (val) {
                                            selectedIndex = val;
                                            setState(() {});
                                          },
                                          unselectedLabelColor: Colors.black,
                                          indicator: BoxDecoration(
                                              borderRadius:
                                              BorderRadius.circular(10),
                                              color: Colors.white),
                                          labelStyle: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black),
                                          unselectedLabelStyle: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400),
                                          indicatorWeight: 2,
                                          tabs: const [
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              children: [
                                                Tab(
                                                  text: "Daily",
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              children: [
                                                Tab(
                                                  text: "Monthly",
                                                ),
                                              ],
                                            ),
                                          ]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 15,
                          ),
                          Row(
                            children: [
                              if (selectedIndex == 0)
                                Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18.0),
                                      child: _customCard(
                                          title: 'Today\'s Sales',
                                          value:
                                          'RS ${state.model.data!.todaySales.toString()}',
                                          icon: Icons.account_balance_wallet,
                                          cardColor: Colors.green),
                                    ))
                              else
                                MonthDashboardChart(
                                    state.model.data!.monthsSales!)
                            ],
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                        ],
                      ),
                    ),
                    Divider(),
                    const SizedBox(
                      height: 5,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: CustomText(
                        text: 'General Stats',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Row(
                        children: [
                          Expanded(
                              child: _customCard(
                                  title: 'Tagged Shops',
                                  value: state.model.data!.shops.toString(),
                                  icon: Icons.storefront,
                                  cardColor: Colors.indigo)),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                              child: _customCard(
                                  title: 'Total Orders',
                                  value: state.model.data!.orders.toString(),
                                  icon: CupertinoIcons.cart,
                                  cardColor: FrontendConfigs.kPrimaryColor)),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    // Pie Chart Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: FrontendConfigs.kAppBorder,
                          border: Border.all(color: Colors.grey.withOpacity(0.4)),
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Pie Chart
                              SizedBox(
                                height: 180,
                                width: 180,
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 0,
                                    sections: _getPieChartSections(state.model.data!),
                                  ),
                                ),
                              ),
                              SizedBox(width: 20),
                              // Legend
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildLegendItem('Target', Colors.blue),
                                    SizedBox(height: 12),
                                    _buildLegendItem('Achieved', Colors.green),
                                    SizedBox(height: 12),
                                    _buildLegendItem('Remaining', Colors.red),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            );
          } else if (state is StatsFailed) {
            return Center(
              child: Text(state.message.toString()),
            );
          } else {
            return Center(
              child: Text("Something went wrong"),
            );
          }
        },
      ),
    );
  }

  Widget _customCard(
      {required String title,
        required String value,
        required IconData icon,
        required Color cardColor}) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
          borderRadius: FrontendConfigs.kAppBorder,
          border: Border.all(color: Colors.grey.withOpacity(0.4)),
          color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0, bottom: 15, top: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: FrontendConfigs.kAppBorder,
                color: cardColor,
              ),
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(
                  icon,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(
              height: 14,
            ),
            CustomText(
              text: title,
              fontWeight: FontWeight.w500,
            ),
            SizedBox(
              height: 5,
            ),
            CustomText(
              text: value,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getPieChartSections(StatModel data) {
    // Get dynamic data from API
    double totalTarget = (data.totalTarget ?? 0).toDouble();
    double achievedTarget = (data.achievedTarget ?? 0).toDouble();

    // Handle case when target is 0
    if (totalTarget == 0) {
      return [
        PieChartSectionData(
          color: Colors.grey,
          value: 1,
          title: 'No Target',
          radius: 90,
          titleStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    }

    // Calculate percentages based on target
    double achievedPercentage = (achievedTarget / totalTarget) * 100;
    double remainingPercentage = achievedPercentage >= 100 ? 0 : 100 - achievedPercentage;

    // If achieved exceeds target, cap it at 100%
    if (achievedPercentage > 100) {
      achievedPercentage = 100;
    }

    List<PieChartSectionData> sections = [];

    // Target section (always shows as blue baseline)
    sections.add(
      PieChartSectionData(
        color: Colors.blue,
        value: totalTarget,
        title: '100%\nTarget',
        radius: 90,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );

    // Achieved section (overlay on target)
    if (achievedTarget > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.green,
          value: achievedTarget > totalTarget ? totalTarget : achievedTarget,
          title: '${achievedPercentage.toStringAsFixed(0)}%\nAchieved',
          radius: 90,
          titleStyle: TextStyle(
            fontSize: achievedTarget > totalTarget ? 12 : 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    // Remaining section (only if not fully achieved)
    if (achievedTarget < totalTarget) {
      double remaining = totalTarget - achievedTarget;
      sections.add(
        PieChartSectionData(
          color: Colors.red,
          value: remaining,
          title: '${remainingPercentage.toStringAsFixed(0)}%\nRemaining',
          radius: 90,
          titleStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return sections;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2)
          ),
        ),
        SizedBox(width: 8),
        CustomText(
          text: label,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ],
    );
  }

  num getTotalEarnings(List<TransactionModel> list) {
    num totalTransaction = 0;
    if (list.isNotEmpty) {
      if (list[0].docId != null) {
        list.map((e) {
          totalTransaction += e.amount!;
        }).toList();
      }
    }

    return totalTransaction;
  }

  num getTodayEarnings(List<TransactionModel> list) {
    num amount = 0.0;
    if (list.isNotEmpty) {
      if (list[0].docId != null) {
        list.map((e) {
          if (DateTime(e.date!.toDate().year, e.date!.toDate().month,
              e.date!.toDate().day, 0, 0) ==
              DateTime(
                  DateTime.now().subtract(Duration(days: 0)).year,
                  DateTime.now().subtract(Duration(days: 0)).month,
                  DateTime.now().subtract(Duration(days: 0)).day,
                  0,
                  0)) {
            amount += e.amount!;
          }
        }).toList();
      }
    }

    return amount;
  }
}