import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';

class RowWidget extends StatelessWidget {
  const RowWidget({super.key, required this.logo, required this.text});
  final String logo;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Image.asset(
              logo,
              height: 28,
              width: 28,
            ),
            const SizedBox(
              width: 10,
            ),
            Expanded(
              child: CustomText(
                text: text,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: FrontendConfigs.kAuthTextColor,
              ),
            )
          ],
        ),
        const SizedBox(
          height: 20,
        )
      ],
    );
  }
}
