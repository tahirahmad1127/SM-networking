import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../infrastructure/model/cart.dart';
import '../../../../../application/cart_provider.dart';

class ItemsCard extends StatelessWidget {
  final CartModel model;

  const ItemsCard({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    var cart = Provider.of<CartProvider>(context);

    // Get discount info
    var discountInfo = cart.getBulkDiscountInfo(model);
    num bulkDiscountValue = discountInfo['value'];
    String bulkDiscountType = discountInfo['type'];
    num originalPrice = cart.getItemOriginalPrice(model);
    num priceAfterBulk = cart.getItemPriceAfterBulkDiscount(model);
    num finalPrice = cart.calculateItemFinalPrice(model);
    bool hasCoupon = cart.itemHasCoupon(model);
    bool hasBulk = bulkDiscountValue > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          borderRadius: FrontendConfigs.kAppBorder,
          color: FrontendConfigs.kTextFieldColor,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
          child: Row(
            children: [
              // Product Image
              SizedBox(
                height: 60,
                width: 60,
                child: ExtendedImage.network(
                  model.image.toString(),
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
                  borderRadius: const BorderRadius.all(Radius.circular(30.0)),
                ),
              ),

              const SizedBox(width: 10),

              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: model.name.toString(),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 4),
                    CustomText(
                      text: model.productDetails.packings.toString(),
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 6),

                    // Price Section - Show ALL prices in sequence
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FINAL PRICE (Always show at top - bold and colored)
                        CustomText(
                          text: "${finalPrice.toStringAsFixed(2)} Rs",
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: FrontendConfigs.kPrimaryColor,
                        ),

                        // Show breakdown only if there's any discount
                        if (hasBulk || hasCoupon) ...[
                          const SizedBox(height: 3),

                          // PRICE AFTER BULK (if coupon is also applied)
                          if (hasBulk && hasCoupon) ...[
                            Row(
                              children: [
                                Text(
                                  "${priceAfterBulk.toStringAsFixed(2)} Rs",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange.shade700,
                                    decoration: TextDecoration.lineThrough,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: CustomText(
                                    text: "COUPON",
                                    fontSize: 8,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],

                          // ORIGINAL PRICE with appropriate badge(s)
                          Row(
                            children: [
                              Text(
                                "${originalPrice.toStringAsFixed(2)} Rs",
                                style: TextStyle(
                                  fontSize: hasBulk && hasCoupon ? 10 : 12,
                                  color: FrontendConfigs.kAuthTextColor,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 5),

                              // Show badges based on what discounts are applied
                              if (hasBulk) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: CustomText(
                                    text: bulkDiscountType == 'Percentage'
                                        ? "${bulkDiscountValue.toInt()}% BULK"
                                        : "${bulkDiscountValue.toStringAsFixed(0)} Rs Flat",
                                    fontSize: hasBulk && hasCoupon ? 8 : 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],

                              // If only coupon (no bulk), show coupon badge here
                              if (hasCoupon && !hasBulk) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: CustomText(
                                    text: "COUPON",
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Quantity Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomText(
                    text: "Quantity",
                    fontSize: 12,
                    color: FrontendConfigs.kAuthTextColor,
                  ),
                  CustomText(
                    text:
                    "${model.quantity} ${model.type.toLowerCase() == 'piece' ? 'PCS' : model.type.toUpperCase()}",
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}