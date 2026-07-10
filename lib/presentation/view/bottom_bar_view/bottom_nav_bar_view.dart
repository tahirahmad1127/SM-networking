import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/presentation/elements/navigation_dialog.dart';
import 'package:sm_networking/presentation/view/attendance/attendance_view.dart';
import 'package:sm_networking/presentation/view/order/order_view.dart';
import 'package:sm_networking/presentation/view/stats/stats_view.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:provider/provider.dart';
import '../map/map_retailers.dart';
import '../profile/profile_view.dart';

class BottomNavBarView extends StatefulWidget {
  const BottomNavBarView({super.key});

  @override
  State<BottomNavBarView> createState() => _BottomNavBarViewState();
}

class _BottomNavBarViewState extends State<BottomNavBarView> {
  int pageIndex = 0;

  advancedStatusCheck(NewVersionPlus newVersion) {
    newVersion.getVersionStatus().then((status) {
      if (status != null && status.canUpdate) {
        newVersion.showUpdateDialog(
          context: context,
          launchModeVersion: LaunchModeVersion.external,
          versionStatus: status,
          allowDismissal: false,
          dialogTitle: 'Update',
          dialogText:
          "A new version of the application is available! Download it from the stores.",
        );
      }
    }).catchError((e) {
      // Silently handle errors (404, network issues, etc.)
      // Version check is non-critical, app continues normally
      debugPrint('Version check failed: $e');
    });
  }

  @override
  void initState() {
    final newVersion = NewVersionPlus(
      iOSId: 'com.devspace.studies',
      androidId: 'com.smnetworking.app.dev',
    );
    advancedStatusCheck(newVersion);
    super.initState();
  }

  final pages = [
    const AttendanceView(), // Attendance
    const GoogleMpaView(), // Customers
    const StatsView(), // Sales
    const OrderView(), // Orders
    const ProfileView(), // More
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        showNavigationDialog(context,
            message: "Do you really want to exit from app?",
            buttonText: "Yes", navigation: () {
              exit(0);
            }, secondButtonText: "No", showSecondButton: true);
        return Future.value(true);
      },
      child: SafeArea(
        child: Scaffold(
          body: pages[pageIndex],
          bottomNavigationBar: buildMyNavBar(context),
        ),
      ),
    );
  }

  Widget buildMyNavBar(BuildContext context) {
    var user = Provider.of<UserProvider>(context);
    final role = user.getSalesUserDetails()?.role ?? '';
    final isOrderBooker = role == 'orderBooker';
    return Container(
      height: 65,
      decoration: const BoxDecoration(color: Colors.white),
      child: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 0️⃣ Attendance (Check-in / Check-out)
            IconButton(
              padding: const EdgeInsets.all(3),
              enableFeedback: false,
              onPressed: () => setState(() => pageIndex = 0),
              icon: pageIndex == 0
                  ? Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                        offset: const Offset(0, 14),
                        blurRadius: 17,
                        spreadRadius: 0,
                        color: FrontendConfigs.kPrimaryColor
                            .withOpacity(0.2)),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xffFF0000).withOpacity(0.1),
                      const Color(0xffFF0000).withOpacity(0.9),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/icons/bottom_navigation_icons/punching_icon.png',
                      height: 22,
                      color: FrontendConfigs.kPrimaryColor,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Attendance",
                      style: TextStyle(
                        fontSize: 11,
                        color: FrontendConfigs.kPrimaryColor,
                      ),
                    ),
                  ],
                ),
              )
                  : Column(
                children: [
                  Image.asset(
                    'assets/icons/bottom_navigation_icons/punching_icon.png',
                    height: 22,
                    color: FrontendConfigs.kAuthTextColor,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Attendance",
                    style: TextStyle(
                      fontSize: 11,
                      color: FrontendConfigs.kAuthTextColor,
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              padding: const EdgeInsets.all(3),
              enableFeedback: false,
              onPressed: () => setState(() => pageIndex = 1),
              icon: pageIndex == 1
                  ? activeNavItem(
                icon: const Icon(Icons.storefront),
                label: isOrderBooker ? "Customers" : "Customers",
              )
                  : inactiveNavItem(
                icon: const Icon(Icons.storefront),
                label: isOrderBooker ? "Customers" : "Customers",
              ),
            ),

            // 2️⃣ Sales
            IconButton(
              padding: const EdgeInsets.all(3),
              enableFeedback: false,
              onPressed: () => setState(() => pageIndex = 2),
              icon: pageIndex == 2
                  ? activeNavItem(
                  svgPath: 'assets/images/target.svg', label: "Sales")
                  : inactiveNavItem(
                  svgPath: 'assets/images/target.svg', label: "Sales"),
            ),

            // 3️⃣ Orders
            IconButton(
              padding: const EdgeInsets.all(3),
              enableFeedback: false,
              onPressed: () => setState(() => pageIndex = 3),
              icon: pageIndex == 3
                  ? activeNavItem(
                  svgPath:
                  'assets/icons/bottom_navigation_icons/order_icon.svg',
                  label: "Orders")
                  : inactiveNavItem(
                  svgPath:
                  'assets/icons/bottom_navigation_icons/order_icon.svg',
                  label: "Orders"),
            ),

            // 4️⃣ More
            IconButton(
              padding: const EdgeInsets.all(3),
              enableFeedback: false,
              onPressed: () => setState(() => pageIndex = 4),
              icon: pageIndex == 4
                  ? activeNavItem(
                  svgPath: 'assets/icons/more_icon.svg', label: "More")
                  : inactiveNavItem(
                  svgPath: 'assets/icons/more_icon.svg', label: "More"),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget for active state
  Widget activeNavItem({String? svgPath, Widget? icon, required String label}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
              offset: const Offset(0, 14),
              blurRadius: 17,
              spreadRadius: 0,
              color: FrontendConfigs.kPrimaryColor.withOpacity(0.2)),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xffFF0000).withOpacity(0.1),
            const Color(0xffFF0000).withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        children: [
          if (svgPath != null)
            SvgPicture.asset(svgPath,
                height: 22, color: FrontendConfigs.kPrimaryColor)
          else if (icon != null)
            IconTheme(data: IconThemeData(color: FrontendConfigs.kPrimaryColor), child: icon),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: FrontendConfigs.kPrimaryColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  /// Helper widget for inactive state
  Widget inactiveNavItem({String? svgPath, Widget? icon, required String label}) {
    return Column(
      children: [
        if (svgPath != null)
          SvgPicture.asset(svgPath,
              height: 22, color: FrontendConfigs.kAuthTextColor)
        else if (icon != null)
          IconTheme(data: IconThemeData(color: FrontendConfigs.kAuthTextColor), child: icon),
        const SizedBox(height: 4),
        Text(label,
            style:
            TextStyle(fontSize: 11, color: FrontendConfigs.kAuthTextColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}