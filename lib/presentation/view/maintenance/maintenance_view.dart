import 'package:flutter/material.dart';

import '../../../configurations/frontend_configs.dart';
import '../../elements/custom_text.dart';

/// Full-screen block shown whenever appConfig/maintenance's
/// `isUnderMaintenance` flag is on (see MaintenanceGate, which decides when
/// this replaces the rest of the app). [title]/[message] are the optional
/// overrides from that same document.
class MaintenanceView extends StatelessWidget {
  final String? title;
  final String? message;

  const MaintenanceView({super.key, this.title, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: FrontendConfigs.kPrimaryColor.withOpacity(0.1),
                  ),
                  child: Icon(
                    Icons.engineering_rounded,
                    size: 60,
                    color: FrontendConfigs.kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 28),
                CustomText(
                  text: (title?.isNotEmpty == true)
                      ? title!
                      : "We'll be right back",
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  textAlign: TextAlign.center,
                  color: const Color(0xFF2D3142),
                ),
                const SizedBox(height: 12),
                CustomText(
                  text: (message?.isNotEmpty == true)
                      ? message!
                      : "The app is currently undergoing scheduled maintenance. "
                          "Please check back shortly — thanks for your patience.",
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  textAlign: TextAlign.center,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          FrontendConfigs.kPrimaryColor.withOpacity(0.6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CustomText(
                      text: "Checking automatically...",
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
