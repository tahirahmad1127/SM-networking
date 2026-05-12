import 'package:flutter/material.dart';

import '../../../configurations/frontend_configs.dart';
import '../app_button.dart';

Future<void> deleteAccountSheet(context) {
  return showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize:MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "are_you_sure",
                    style: FrontendConfigs.kTitleStyle,
                  ),
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      }, icon: const Icon(Icons.close))
                ],
              ),
            ),
            Divider(
              color: FrontendConfigs.kAuthTextColor,
              thickness: 0.2,
            ),
            const SizedBox(
              height: 12,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal:18.0),
              child: RichText(
                  text:  TextSpan(
                      text: "Are you sure you want to ",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: FrontendConfigs.kAuthTextColor),
                      children: [
                      TextSpan(
                      text: "delete your account permanently ",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: FrontendConfigs.kPrimaryColor),),
                  TextSpan(
                      text: "This will erase all your saved data, order history, and personalized recommendations. Click",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: FrontendConfigs.kAuthTextColor)),
                        const TextSpan(
                            text: " Delete ",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black)),
                        TextSpan(
                            text: "to proceed, or",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: FrontendConfigs.kAuthTextColor)),
                        const TextSpan(
                            text: " Cancel ",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black)),
                        TextSpan(
                            text: "to keep your account and data intact",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: FrontendConfigs.kAuthTextColor)),
                      ])),
            ),
            const SizedBox(height:18,),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(
                          color: FrontendConfigs.kAuthTextColor, width: 0.5))),
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AppButton(
                      onPressed: () {},
                      btnLabel: "Cancel",
                      width: MediaQuery.of(context).size.width / 2.25,
                      btnColor: const Color(0xff121212),
                    ),
                    AppButton(
                      onPressed: () {},
                      btnLabel: "Yes, Delete it",
                      width: MediaQuery.of(context).size.width / 2.25,
                    )
                  ],
                ),
              ),
            ),
          ],
        );
      });
}
