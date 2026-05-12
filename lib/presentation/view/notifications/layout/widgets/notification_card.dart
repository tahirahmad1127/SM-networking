import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';

import '../../../../../infrastructure/model/notification.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel model;

  const NotificationCard({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          borderRadius: FrontendConfigs.kAppBorder,
          color: FrontendConfigs.kTextFieldColor,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    "assets/images/discount_icon.png",
                    height: 38,
                    width: 38,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 7,
                      ),
                      CustomText(text: model.title.toString()),
                      const SizedBox(
                        height: 5,
                      ),
                      SizedBox(
                          width: MediaQuery.of(context).size.width / 2,
                          child: CustomText(
                            text: model.subTitle.toString(),
                            fontSize: 12,
                            color: FrontendConfigs.kAuthTextColor,
                          )),
                    ],
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: CustomText(
                  text: DateFormat.yMd()
                      .format(model.createdAt!.toDate())
                      .toString(),
                  fontSize: 12,
                  color: FrontendConfigs.kAuthTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
