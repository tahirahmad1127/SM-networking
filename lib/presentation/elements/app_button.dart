import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';

class AppButton extends StatelessWidget {
  VoidCallback onPressed;
  String btnLabel;
  double width;
  double height;
  Color? textColor;
  Color? btnColor;

  AppButton(
      {super.key,
      required this.onPressed,
      required this.btnLabel,
      this.btnColor,
      this.textColor = Colors.white,
      this.width = double.infinity,
      this.height = 56});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: btnColor ?? FrontendConfigs.kPrimaryColor,
          fixedSize: Size(width, height),
          shape: RoundedRectangleBorder(
            borderRadius: FrontendConfigs.kAppBorder,
          )),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            btnLabel,
            style: TextStyle(
              color: textColor!,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
