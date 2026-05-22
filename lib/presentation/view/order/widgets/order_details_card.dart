import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/order.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';

import '../order_details/layout/order_card.dart';

class OrderDetailsCard extends StatelessWidget {
  final OrderModel model;

  const OrderDetailsCard({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    log(model.toJson().toString());

    // Status from API is e.g. "Placed", "Processed", "Delivered", "Completed", "Cancelled"
    final String currentStatus = (model.status ?? '').toUpperCase();
    String expectedDeliveryText;
    if (currentStatus == "COMPLETED" || currentStatus == "DELIVERED") {
      expectedDeliveryText = "Delivered";
    } else if (currentStatus == "CANCELLED") {
      expectedDeliveryText = "-";
    } else if (model.expectedDelivery != null) {
      // Use the API's expectedDelivery field directly — it's always present for active orders
      expectedDeliveryText = DateFormat("d MMM yyyy, h:mm a")
          .format(DateTime.parse(model.expectedDelivery!).toLocal());
    } else if (model.createdAt != null) {
      // Fallback: createdAt + 24h if expectedDelivery somehow missing
      expectedDeliveryText = DateFormat("d MMM yyyy, h:mm a")
          .format(model.createdAt!.add(const Duration(hours: 24)));
    } else {
      expectedDeliveryText = "-";
    }

    // Get discount values from API
    final bulkDiscount = model.bulkDiscount ?? 0;
    final couponDiscount = model.couponDiscount ?? 0;
    final hasAnyDiscount = bulkDiscount > 0 || couponDiscount > 0;

    // Calculate original total (before discounts)
    final num totalAfterDiscounts = model.total ?? 0;
    final num originalTotal = totalAfterDiscounts + bulkDiscount + couponDiscount;

    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          borderRadius: FrontendConfigs.kAppBorder, color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              "Order Details",
              style: FrontendConfigs.kTitleStyle,
            ),
          ),
          FrontendConfigs.appDivider,
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  text: "Order ID",
                  color: FrontendConfigs.kAuthTextColor,
                  fontSize: 12,
                ),
                CustomText(
                  text: "#${model.id.toString().substring(0, 8).toUpperCase()}",
                  fontSize: 14,
                ),
                const SizedBox(height: 16),
                CustomText(
                  text: "Number of Items",
                  color: FrontendConfigs.kAuthTextColor,
                  fontSize: 12,
                ),
                CustomText(
                  text: model.items!.length.toString(),
                  fontSize: 14,
                ),
                const SizedBox(height: 16),
                CustomText(
                  text: "Item Details",
                  color: FrontendConfigs.kAuthTextColor,
                  fontSize: 12,
                ),
                ListView.builder(
                  itemCount: model.items!.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, i) {
                    return OrderItemCard(
                      model: model.items![i],
                    );
                  },
                ),
                const SizedBox(height: 16),
                CustomText(
                  text: "Delivery Address",
                  color: FrontendConfigs.kAuthTextColor,
                  fontSize: 12,
                ),
                CustomText(
                  text: (model.shippingAddress?.isNotEmpty == true)
                      ? model.shippingAddress!
                      : '-',
                  fontSize: 14,
                ),
                const SizedBox(height: 16),
                CustomText(
                  text: (currentStatus == "COMPLETED" || currentStatus == "DELIVERED")
                      ? "Delivery"
                      : "Expected Delivery",
                  color: FrontendConfigs.kAuthTextColor,
                  fontSize: 12,
                ),
                CustomText(
                  text: expectedDeliveryText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: (currentStatus == "COMPLETED" || currentStatus == "DELIVERED")
                      ? FrontendConfigs.kGreenColor
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FrontendConfigs.appDivider,

          // Bill Summary Section
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasAnyDiscount) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        text: "Subtotal (Original)",
                        fontSize: 13,
                        color: FrontendConfigs.kAuthTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                      CustomText(
                        text: "${originalTotal.toStringAsFixed(2)} Rs",
                        fontSize: 13,
                        color: FrontendConfigs.kAuthTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (bulkDiscount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_offer,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            CustomText(
                              text: "Bulk Discount",
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                        CustomText(
                          text: "- ${bulkDiscount.toStringAsFixed(2)} Rs",
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (couponDiscount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.confirmation_number,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 4),
                            CustomText(
                              text: "Coupon Discount",
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                        CustomText(
                          text: "- ${couponDiscount.toStringAsFixed(2)} Rs",
                          fontSize: 12,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  const SizedBox(height: 4),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CustomText(
                      text: "Total",
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    CustomText(
                      text: "${totalAfterDiscounts.toStringAsFixed(2)} Rs",
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: FrontendConfigs.kPrimaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}