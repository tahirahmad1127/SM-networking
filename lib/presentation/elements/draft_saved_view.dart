import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/configurations/translation_helper.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:sm_networking/presentation/view/bottom_bar_view/bottom_nav_bar_view.dart';

import 'app_button.dart';

class DraftSavedView extends StatelessWidget {
  const DraftSavedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
        child: AppButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                  builder: (context) => const BottomNavBarView()),
                  (route) => false,
            );
          },
          btnLabel: 'Continue Shopping',
          width: MediaQuery.of(context).size.width / 2.25,
          btnColor: const Color(0xff121212),
          height: 48,
        ),
      ),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/confirm_bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Draft icon — using a styled container to match the truck asset style
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: FrontendConfigs.kPrimaryColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.drafts_outlined,
                      size: 64,
                      color: FrontendConfigs.kPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: CustomText(
                  text: 'Order Saved to Drafts!',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                child: CustomText(
                  text:
                  'Your order has been saved as a draft. You can find it in the Drafts tab in your Orders screen.',
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}