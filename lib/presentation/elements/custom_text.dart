import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  CustomText({super.key,
    required this.text,
    this.color,
    this.textAlign,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w500,
    this.overflow,
    this.maxLines,
    this.fontFamily,
    this.decoration,
    this.letterSpacing});

  String text;
  FontWeight fontWeight;
  double fontSize;
  Color? color = Colors.black;
  double? letterSpacing;
  TextAlign? textAlign;
  TextOverflow? overflow;
  int? maxLines;
  String? fontFamily;
  TextDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return Text(
      textAlign: textAlign,
      text,
      maxLines: maxLines,
      style: TextStyle(
          fontWeight: fontWeight,
          fontSize: fontSize,
          color: color,
          decoration: decoration,
          overflow: overflow,
          fontFamily: fontFamily,
          letterSpacing: letterSpacing),
    );
  }
}
