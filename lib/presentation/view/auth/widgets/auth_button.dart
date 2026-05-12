import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';

class AuthButton extends StatelessWidget {
  VoidCallback onPressed;
  String name;
  String title;
  double width;
  double height;
  Color ?textColor;

  AuthButton(
      {super.key, required this.onPressed,
        required this.name,
        required this.title,
        this.textColor=Colors.white,
        this.width = double.infinity,
        this.height = 56});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor:Colors.white,
          side: BorderSide(color:const Color(0xff000000).withOpacity(0.1)),
          fixedSize: Size(width, height),
          elevation:0,
          shape: RoundedRectangleBorder(
            borderRadius: FrontendConfigs.kAppBorder,
          )),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment:MainAxisAlignment.center,
        children: [
          Column(
            mainAxisAlignment:MainAxisAlignment.center,
            children: [
              Text(
                title,
                style:  const TextStyle(
                  color:Color(0xffBDBDBD),
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),),
              Text(
                name,
                style:  TextStyle(

                  color:FrontendConfigs.kPrimaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),)
            ],
          ),
        ],
      ),
    );
  }
}
