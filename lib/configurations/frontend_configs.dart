import 'package:flutter/material.dart';

class FrontendConfigs {
  static Color kPrimaryColor = const Color(0xff4282fe);
  static Color kTextFieldColor = const Color(0xffEEF0F6);
  static Color kGreenColor = const Color(0xff17B556);
  static Color kAuthTextColor = const Color(0xff949494);
  static BorderRadius kAppBorder = BorderRadius.circular(10);
  static Divider appDivider = const Divider(
    color: Color(
      0xffEEF0F6,
    ),
    thickness: 1,
  );
  static TextStyle kHeadingStyle = const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 28,
      color: Color(0xff121212),
      fontFamily: "Inter");
  static TextStyle kSubHeadingStyle = const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 24,
      color: Color(0xff121212),
      fontFamily: "Inter");
  static TextStyle kTitleStyle = const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 18,
      color: Color(0xff121212),
      fontFamily: "Inter");
  static String appName = "Karyana";
}
