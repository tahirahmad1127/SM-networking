import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sm_networking/application/retailer_provider.dart';
import 'package:sm_networking/infrastructure/model/agent.dart';
import 'package:sm_networking/infrastructure/model/retailer.dart' hide userModelToJson;
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:sm_networking/presentation/view/auth/log_in/log_in_view.dart';
import 'package:sm_networking/presentation/view/auth/welcome/welcome_view.dart';
import 'package:provider/provider.dart';

import '../../../../application/checkIn_provider.dart';
import '../../../../application/user_provider.dart';
import '../../../../infrastructure/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../infrastructure/services/auth.dart';
import '../../bottom_bar_view/bottom_nav_bar_view.dart';

class SplashBody extends StatefulWidget {
  const SplashBody({super.key});

  @override
  State<SplashBody> createState() => _SplashBodyState();
}

class _SplashBodyState extends State<SplashBody> {

  Future<bool> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var userProvider = Provider.of<UserProvider>(context, listen: false);

    if (prefs.getString('USER_DATA') != null) {
      // 1. Load cached data first
      UserModel userModel = userModelFromJson(prefs.getString('USER_DATA')!);
      userProvider.saveSalesUserDetails(userModel);

      // 2. Refresh from API in background
      await _refreshUserDataFromAPI(userModel, userProvider);

      return Future.value(true);
    } else {
      return Future.value(false);
    }
  }

  /// Fetch fresh user data from API
  Future<void> _refreshUserDataFromAPI(UserModel currentUserModel, UserProvider userProvider) async {
    try {
      debugPrint("🔄 Fetching latest user data from API...");

      final userId = currentUserModel.user?.id;
      if (userId == null) return;

      // Call API
      final authRepository = AuthRepositoryImp();
      final result = await authRepository.getUserByID(userId);

      result.fold(
            (error) {
          debugPrint("⚠️ Failed to refresh: ${error.error}");
        },
            (freshUser) async {
          debugPrint("✅ Fresh user data retrieved");

          // Create updated model (keep same token)
          final updatedUserModel = UserModel(
            token: currentUserModel.token,
            user: freshUser,
          );

          // Update provider
          userProvider.saveSalesUserDetails(updatedUserModel);

          // Save to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('USER_DATA', userModelToJson(updatedUserModel));

          // Update check-in times
          if (mounted) {
            final checkInProvider = context.read<CheckInProvider>();
            final checkInTime = freshUser.checkInTime ?? "09:00";
            final checkOutTime = freshUser.checkOutTime ?? "17:00";

            checkInProvider.setAllowedTimes(
              checkInTime: checkInTime,
              checkOutTime: checkOutTime,
            );

            await prefs.setString('ALLOWED_CHECKIN_TIME', checkInTime);
            await prefs.setString('ALLOWED_CHECKOUT_TIME', checkOutTime);

            debugPrint("✅ Times updated: $checkInTime - $checkOutTime");
          }
        },
      );
    } catch (e) {
      debugPrint("❌ Error: $e");
    }
  }

  @override
  void initState() {
    FirebaseAuth.instance.signInAnonymously();
    Timer(const Duration(seconds: 3), () async {
      getData().then((value) {
        if (value == true) {
          var userProvider =
          Provider.of<UserProvider>(context, listen: false);
          if (userProvider.getSalesUserDetails()!.user!.isActive == false) {
            getFlushBar(context,
                title: "Sorry! Your account has been disabled by Karyana.");
          } else if (userProvider.getSalesUserDetails()!.user!.isAdminVerified == false) {
            getFlushBar(context,
                title: "Sorry! Your account is under approval by Karyana.");
          } else {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const BottomNavBarView()));
          }
        } else {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const LogInView()));

        }
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/appLogo_clean.png',
            // height: 150,
            // width: 200,
          ),
        ],
      ),
    );
  }
}
