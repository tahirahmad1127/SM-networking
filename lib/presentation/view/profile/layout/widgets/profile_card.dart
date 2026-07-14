import 'package:flutter/material.dart';
import '../../../../../configurations/frontend_configs.dart';
import '../../../../elements/custom_text.dart';

class ProfileCard extends StatelessWidget {
  ProfileCard({super.key, required this.lebal, this.textColor});
  final String lebal;
  Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          borderRadius: FrontendConfigs.kAppBorder,
          color: FrontendConfigs.kTextFieldColor),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              text: lebal,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor ?? Colors.black,
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: FrontendConfigs.kAuthTextColor,
            )
          ],
        ),
      ),
    );
  }
}
