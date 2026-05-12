import 'package:another_stepper/dto/stepper_data.dart';
import 'package:another_stepper/widgets/another_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/configurations/translation_helper.dart';
import 'package:sm_networking/infrastructure/model/order.dart';
import 'package:sm_networking/presentation/view/order/order_details/layout/order_card.dart';
import 'package:sm_networking/presentation/view/order/widgets/order_details_card.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../check_out/layout/widgets/items_card.dart';

class OrderDetailsBody extends StatefulWidget {
  final OrderModel model;

  const OrderDetailsBody({Key? key, required this.model}) : super(key: key);

  @override
  State<OrderDetailsBody> createState() => _OrderDetailsBodyState();
}

class _OrderDetailsBodyState extends State<OrderDetailsBody> {
  List<StepperData> stepperData = [];

  @override
  initState() {
    stepperData = widget.model.statuses!
        .map((e) => StepperData(
            title: StepperText(
             e.status.toString(),
              textStyle: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontSize: 12),
            ),
            subtitle: StepperText(
              "${DateFormat.yMMMEd().format(e.date!)} ${DateFormat.jm().format(e.date!)}",
              textStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  fontSize: 14),
            ),
            iconWidget: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: FrontendConfigs.kTextFieldColor,
                  borderRadius: FrontendConfigs.kAppBorder),
              child:
                  Icon(Icons.check_circle, color: FrontendConfigs.kGreenColor),
            )))
        .toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  TranslationHelper.getTranslatedText("order_details"),
                  style: FrontendConfigs.kSubHeadingStyle,
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 35,
                      child: IconButton(
                          onPressed: () {
                            _launchUrl(
                                "https://wa.me/+923350059585?text=${Uri.parse("Welcome to Karyana!")}");
                          },
                          icon: SvgPicture.asset("assets/icons/whatsapp.svg")),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(
              height: 12,
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                  borderRadius: FrontendConfigs.kAppBorder,
                  color: Colors.white),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationHelper.getTranslatedText("order_tracking"),
                      style: FrontendConfigs.kTitleStyle,
                    ),
                    AnotherStepper(
                      verticalGap: 30,
                      stepperList: stepperData,
                      stepperDirection: Axis.vertical,
                      inActiveBarColor: FrontendConfigs.kTextFieldColor,
                      activeBarColor: FrontendConfigs.kGreenColor,
                      barThickness: 2,
                      iconWidth: 40,
                      activeIndex: getSelectedIndex(),
                      // Height that will be applied to all the stepper icons
                      iconHeight:
                          40, // Width that will be applied to all the stepper icons
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 18,
            ),
            SizedBox(
              height: 15,
            ),
            OrderDetailsCard(
              model: widget.model,
            ),
            const SizedBox(
              height: 34,
            ),
          ]),
        ),
      ),
    );
  }

  int getSelectedIndex() {
    if (widget.model.status == "PENDING") {
      return 0;
    } else if (widget.model.status == "PROCESSED") {
      return 1;
    } else if (widget.model.status == "DELIVERED") {
      return 2;
    } else if (widget.model.status == "COMPLETED" ||
        widget.model.status == "CANCELLED") {
      return 3;
    } else {
      return 0;
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
