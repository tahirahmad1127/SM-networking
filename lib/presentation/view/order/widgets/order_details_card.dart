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

    // Get discount values from API
    final bulkDiscount = model.bulkDiscount ?? 0;
    final couponDiscount = model.couponDiscount ?? 0;
    final hasAnyDiscount = bulkDiscount > 0 || couponDiscount > 0;

    // Calculate original total (before discounts)
    final totalAfterDiscounts = model.total ?? 0;
    final originalTotal = totalAfterDiscounts + bulkDiscount + couponDiscount;

    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
          borderRadius: FrontendConfigs.kAppBorder, color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 12,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              "Order Details",
              style: FrontendConfigs.kTitleStyle,
            ),
          ),
          FrontendConfigs.appDivider,
          const SizedBox(
            height: 8,
          ),
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
                  text: "#" +
                      model.id.toString().substring(0, 8).toUpperCase(),
                  fontSize: 14,
                ),
                const SizedBox(
                  height: 16,
                ),
                CustomText(
                  text: "Number of Items",
                  color: FrontendConfigs.kAuthTextColor,
                  fontSize: 12,
                ),
                CustomText(
                  text: model.items!.length.toString(),
                  fontSize: 14,
                ),
                const SizedBox(
                  height: 16,
                ),
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
                      return OrderCard(
                        model: model.items![i],
                      );
                    }),
                const SizedBox(
                  height: 16,
                ),
                CustomText(
                  text: "Delivery Address",
                  color: FrontendConfigs.kAuthTextColor,
                  fontSize: 12,
                ),
                CustomText(
                  text: model.retailerUser!.shopAddress1.toString(),
                  fontSize: 14,
                ),
                const SizedBox(
                  height: 16,
                ),
                CustomText(
                  text: "Expected Delivery",
                  color: FrontendConfigs.kAuthTextColor,
                  fontSize: 12,
                ),
                if (model.statuses!.length > 1)
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
          ),
          const SizedBox(
            height: 16,
          ),
          FrontendConfigs.appDivider,

          // Bill Summary Section
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show discount breakdown if any discount exists
                if (hasAnyDiscount) ...[
                  // Original subtotal (before any discounts)
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
                      )
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Bulk discount (applied first)
                  if (bulkDiscount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_offer, color: Colors.green, size: 16),
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
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Coupon discount (applied after bulk discount)
                  if (couponDiscount > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.confirmation_number, color: Colors.orange, size: 16),
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
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Divider line
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  const SizedBox(height: 4),
                ],

                // Total row
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