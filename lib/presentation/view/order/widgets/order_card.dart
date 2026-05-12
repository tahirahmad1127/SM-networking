import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sm_networking/infrastructure/model/order.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:sm_networking/presentation/view/order/order_details/order_details_view.dart';

import '../../../../configurations/frontend_configs.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.status,
    required this.model,
  });
  final String status;
  final OrderModel model;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
      child: Container(
        height: 150,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            color: FrontendConfigs.kTextFieldColor,
            borderRadius: FrontendConfigs.kAppBorder),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 6,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                          text: "ID # ${(model.id ?? 'N/A').substring(0, model.id != null && model.id!.length >= 8 ? 8 : (model.id?.length ?? 0)).toUpperCase()}"),
                      const SizedBox(
                        height: 3,
                      ),
                      CustomText(
                        text: "${model.items?.length ?? 0} Items",
                        fontSize: 12,
                        color: FrontendConfigs.kAuthTextColor,
                      ),
                      const SizedBox(
                        height: 3,
                      ),
                      CustomText(
                        text: model.retailerUser?.name ?? 'N/A',
                        fontSize: 12,
                        color: FrontendConfigs.kAuthTextColor,
                      ),
                      const SizedBox(
                        height: 18,
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text: "Amount",
                                fontSize: 12,
                                color: FrontendConfigs.kAuthTextColor,
                              ),
                              CustomText(
                                text: "${model.total?.toStringAsFixed(0) ?? '0'} Rs",
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: FrontendConfigs.kPrimaryColor,
                              )
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18.0),
                            child: Container(
                              height: 22,
                              width: 1,
                              color: FrontendConfigs.kAuthTextColor
                                  .withOpacity(0.5),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text: "Expected Delivery",
                                fontSize: 12,
                                color: FrontendConfigs.kAuthTextColor,
                              ),
                              if ((model.statuses?.length ?? 0) > 1 &&
                                  model.status != "Cancelled" &&
                                  model.expectedDelivery != null)
                                CustomText(
                                  text: DateFormat.yMMMEd().format(
                                      DateTime.parse(model.expectedDelivery!)),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                )
                              else
                                CustomText(
                                  text: "-",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                )
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: FrontendConfigs.kAppBorder,
                      color: getColor().withOpacity(0.1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CustomText(
                        text: status,
                        fontSize: 12,
                        color: getColor(),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getColor() {
    if (status == "Pending") {
      return Colors.black;
    } else if (status == "Completed") {
      return FrontendConfigs.kGreenColor;
    } else if (status == "Cancelled") {
      return FrontendConfigs.kPrimaryColor;
    } else if (status == "Processed") {
      return FrontendConfigs.kPrimaryColor;
    } else {
      return Colors.white;
    }
  }
}