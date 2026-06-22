import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sm_networking/infrastructure/model/order.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';

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
    final String upperStatus = status.toUpperCase();
    String expectedDeliveryText = "-";
    if (upperStatus == "COMPLETED" || upperStatus == "DELIVERED") {
      expectedDeliveryText = "Delivered";
    } else if (upperStatus == "CANCELLED") {
      expectedDeliveryText = "-";
    } else if (model.expectedDelivery != null) {
      expectedDeliveryText = DateFormat("d MMM yyyy, h:mm a")
          .format(DateTime.parse(model.expectedDelivery!).toLocal());
    } else if (model.createdAt != null) {
      expectedDeliveryText = DateFormat("d MMM yyyy, h:mm a")
          .format(model.createdAt!.add(const Duration(hours: 24)));
    }

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
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                          text:
                          "ID # ${(model.id ?? 'N/A').substring(0, model.id != null && model.id!.length >= 8 ? 8 : (model.id?.length ?? 0)).toUpperCase()}"),
                      const SizedBox(height: 3),
                      CustomText(
                        text: "${model.items?.length ?? 0} Items",
                        fontSize: 12,
                        color: FrontendConfigs.kAuthTextColor,
                      ),
                      const SizedBox(height: 3),
                      CustomText(
                        text: model.warehouseManager?.name ?? 'N/A',
                        fontSize: 12,
                        color: FrontendConfigs.kAuthTextColor,
                      ),
                      const SizedBox(height: 18),
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
                                text:
                                "${model.total?.toStringAsFixed(2) ?? '0'} Rs",
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: FrontendConfigs.kPrimaryColor,
                              ),
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
                                text: (upperStatus == "COMPLETED" || upperStatus == "DELIVERED")
                                    ? "Delivery"
                                    : "Expected Delivery",
                                fontSize: 12,
                                color: FrontendConfigs.kAuthTextColor,
                              ),
                              CustomText(
                                text: expectedDeliveryText,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: (upperStatus == "COMPLETED" || upperStatus == "DELIVERED")
                                    ? FrontendConfigs.kGreenColor
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color getColor() {
    final s = status.toUpperCase();
    if (s == "PLACED" || s == "PENDING") {
      return Colors.black;
    } else if (s == "COMPLETED" || s == "DELIVERED") {
      return FrontendConfigs.kGreenColor;
    } else if (s == "CANCELLED") {
      return FrontendConfigs.kPrimaryColor;
    } else if (s == "PROCESSED") {
      return FrontendConfigs.kPrimaryColor;
    } else {
      return Colors.black54;
    }
  }
}