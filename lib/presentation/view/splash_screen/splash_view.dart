import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:sm_networking/presentation/view/splash_screen/layout/body.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FrontendConfigs.kPrimaryColor,
      bottomNavigationBar: Column(

        mainAxisSize:MainAxisSize.min,
        children: [
          CustomText(
            text: "Saad Enterprises",
            color: Colors.white,
            fontSize:16,
          ),
          const SizedBox(height:20,)
        ],
      ),
      body: const SplashBody(),
    );
  }
}
