import 'package:flutter/material.dart';

AppBar customAppBar(
  BuildContext context, {
  String? text,
  bool showText = false,
}) {
  return AppBar(
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(
        Icons.arrow_back,
        color: Colors.black,
        size: 24,
      ),
      onPressed: () {
        Navigator.pop(context);
      },
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    title: showText
        ? Text(
            text!,
            style: TextStyle(color: Colors.black),
          )
        : null,
  );
}
