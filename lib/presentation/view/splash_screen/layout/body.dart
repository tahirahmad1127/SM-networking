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
import '../../../../infrastructure/services/install_session.dart';
import '../../bottom_bar_view/bottom_nav_bar_view.dart';

class SplashBody extends StatefulWidget {
  const SplashBody({super.key});

  @override
  State<SplashBody> createState() => _SplashBodyState();
}

class _SplashBodyState extends State<SplashBody> {

  Future<bool> getData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (await InstallSession.clearSessionIfReinstalled(prefs)) {
      await FirebaseAuth.instance.signOut();
      return Future.value(false);
    }

    var userProvider = Provider.of<UserProvider>(context, listen: false);

    if (prefs.getString('USER_DATA') != null) {
      // 1. Load cached data first (includes distributors from last login)
      UserModel userModel = userModelFromJson(prefs.getString('USER_DATA')!);
      userProvider.saveSalesUserDetails(userModel);

      // 2. Refresh user profile from API — preserves distributors & role
      await _refreshUserDataFromAPI(userModel, userProvider);

      return Future.value(true);
    } else {
      return Future.value(false);
    }
  }

  /// Fetches a fresh user profile from the API and merges it with the cached
  /// model, deliberately keeping [role] and [distributors] from the cache.
  ///
  /// WHY: getUserByID only returns a [] profile object — the server does
  /// NOT re-send the distributors list on this endpoint. If we replace the
  /// whole [UserModel] we silently discard distributors and they vanish on
  /// every app restart after the first cold-launch login.
  Future<void> _refreshUserDataFromAPI(
      UserModel currentUserModel, UserProvider userProvider) async {
    try {
      debugPrint("🔄 Fetching latest user data from API...");

      final userId = currentUserModel.user?.id;
      if (userId == null) return;

      final authRepository = AuthRepositoryImp();
      final result = await authRepository.getUserByID(userId);

      result.fold(
            (error) {
          // Cached data (with distributors) is already loaded — safe to ignore.
          debugPrint("⚠️ Failed to refresh user profile: ${error.error}");
        },
            (freshUser) async {
          debugPrint("✅ Fresh user profile retrieved");

          // ✅ CRITICAL: keep role + all lists from the cached login response.
          // Only the User profile object (name, times, etc.) is refreshed here.
          // getUserByID does NOT re-send distributors/wholesalers/retailers,
          // so we must carry them forward from the cached model or they vanish.
          final updatedUserModel = UserModel(
            token: currentUserModel.token,
            user: freshUser,
            role: currentUserModel.role,
            distributors: currentUserModel.distributors,
            wholesalers: currentUserModel.wholesalers,   // ← was missing
            retailers: currentUserModel.retailers,       // ← was missing
            totalWholesalers: currentUserModel.totalWholesalers,
            totalRetailers: currentUserModel.totalRetailers,
          );

          // Update provider and persist the merged model
          userProvider.saveSalesUserDetails(updatedUserModel);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('USER_DATA', userModelToJson(updatedUserModel));

          // Update check-in / check-out times
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
      debugPrint("❌ Error refreshing user data: $e");
    }
  }

  @override
  void initState() {
    FirebaseAuth.instance.signInAnonymously();
    Timer(const Duration(seconds: 3), () async {
      getData().then((value) {
        if (value == true) {
          var userProvider = Provider.of<UserProvider>(context, listen: false);
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
              MaterialPageRoute(builder: (context) => const LogInView()));
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
            'assets/images/whitelogo.png',
          ),
        ],
      ),
    );
  }
}