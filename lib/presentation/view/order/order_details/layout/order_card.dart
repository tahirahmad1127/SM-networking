import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../infrastructure/model/order.dart';

/// Item-level order card used inside Order Details.
/// Takes a single [Item] and an optional [orderCreatedAt] (for expected delivery).
class OrderItemCard extends StatelessWidget {
  final Item model;
  final String? status;
  final DateTime? orderCreatedAt;

  const OrderItemCard({
    super.key,
    required this.model,
    this.status,
    this.orderCreatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final int originalPrice = model.price!;
    final int discountedPrice = model.discountedPrice!;
    final bool hasDiscount = originalPrice != discountedPrice;

    // Expected delivery = order placement + 24 hours (Pending tab only)
    final DateTime? expectedDelivery =
    orderCreatedAt?.add(const Duration(hours: 24));
    final String? expectedDeliveryStr = expectedDelivery != null
        ? DateFormat("d MMM yyyy, h:mm a").format(expectedDelivery)
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dynamic height: grows with content, minimum 92
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 92),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: ExtendedImage.network(
                            model.productId!.image.toString(),
                            cacheHeight: 200,
                            cacheWidth: 200,
                            fit: BoxFit.fill,
                            cache: true,
                            loadStateChanged: (ExtendedImageState state) {
                              switch (state.extendedImageLoadState) {
                                case LoadState.loading:
                                  return Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Image.asset(
                                      "assets/images/karyana.png",
                                      fit: BoxFit.fill,
                                      color: Colors.grey,
                                    ),
                                  );
                                case LoadState.failed:
                                  return Image.asset(
                                    "assets/images/karyana.png",
                                    fit: BoxFit.fill,
                                    color: Colors.grey[350],
                                  );
                                default:
                                  return state.completedWidget;
                              }
                            },
                            borderRadius:
                            const BorderRadius.all(Radius.circular(30.0)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: CustomText(
                                text: model.productId!.englishTitle.toString()),
                          ),
                          const SizedBox(height: 4),
                          const SizedBox(height: 4),
                          if (hasDiscount)
                            Row(
                              children: [
                                CustomText(
                                  text: "${originalPrice.toStringAsFixed(0)} Rs",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                                const SizedBox(width: 8),
                                CustomText(
                                  text: "${discountedPrice.toStringAsFixed(0)} Rs",
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: FrontendConfigs.kPrimaryColor,
                                ),
                              ],
                            )
                          else
                            CustomText(
                              text: "${discountedPrice.toStringAsFixed(0)} Rs",
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: FrontendConfigs.kPrimaryColor,
                            ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CustomText(
                        text: "Quantity",
                        fontSize: 12,
                        color: FrontendConfigs.kAuthTextColor,
                      ),
                      CustomText(
                        text:
                        "${model.quantity!} ${model.type!.toLowerCase() == 'piece' ? 'PCS' : model.type!.toLowerCase() == 'ctn' ? 'CTN' : model.type}",
                        fontSize: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Expected delivery row — only shown on Pending tab
        if (expectedDeliveryStr != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 14, color: FrontendConfigs.kPrimaryColor),
                const SizedBox(width: 5),
                CustomText(
                  text: "Expected Delivery: ",
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
                CustomText(
                  text: expectedDeliveryStr,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FrontendConfigs.kPrimaryColor,
                ),
              ],
            ),
          ),

        const Divider(height: 0),
      ],
    );
  }
}