import 'package:flutter/material.dart';
import '../../../../configurations/translation_helper.dart';
import '../log_in/log_in_view.dart';
import '../widgets/auth_button.dart';
import 'layout/body.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: Container(
        color: Colors.white,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18.0, right: 18, left: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthButton(
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LogInView()));
                },
                name: TranslationHelper.getTranslatedText("login"),
                title: TranslationHelper.getTranslatedText("have_an_account"),
              ),
            ],
          ),
        ),
      ),
      body: const WelcomeBody(),
    );
  }
}
