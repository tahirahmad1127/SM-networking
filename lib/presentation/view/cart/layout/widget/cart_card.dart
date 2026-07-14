import 'dart:developer';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sm_networking/application/cart_provider.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../../infrastructure/model/cart.dart';

class CartCard extends StatefulWidget {
  final CartModel model;

  const CartCard({super.key, required this.model});

  @override
  State<CartCard> createState() => _CartCardState();
}

class _CartCardState extends State<CartCard> {
  bool isEnabled = true;

  num quantity = 1;

  @override
  void initState() {
    quantity = widget.model.quantity;
    setState(() {});
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<UserProvider>(context);
    log("Cart Card: ${widget.model.type.toString()}");
    var cart = Provider.of<CartProvider>(context);

    // Get bulk discount info
    var discountInfo = cart.getBulkDiscountInfo(widget.model);
    num bulkDiscountValue = discountInfo['value'];
    String bulkDiscountType = discountInfo['type'];
    num finalPrice = cart.calculateItemFinalPrice(widget.model);
    num originalPrice = cart.getItemPriceWithoutBulkDiscount(widget.model);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
      child: Slidable(
        key: ValueKey(widget.model.hashCode),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            InkWell(
              onTap: () {
                cart.removeItem(widget.model.id);
              },
              child: Container(
                height: 92,
                width: 187,
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10)),
                    color: FrontendConfigs.kPrimaryColor,
                    gradient: LinearGradient(
                        begin: Alignment.bottomLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          FrontendConfigs.kPrimaryColor.withOpacity(0.6),
                          FrontendConfigs.kPrimaryColor,
                        ])),
                child: Padding(
                  padding: const EdgeInsets.only(left: 24.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete,
                        color: Colors.white,
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      CustomText(
                        text: "Delete",
                        color: Colors.white,
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
        child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              borderRadius: FrontendConfigs.kAppBorder,
              color: FrontendConfigs.kTextFieldColor,
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    SizedBox(
                      height: 60,
                      width: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ExtendedImage.network(
                          widget.model.productDetails.image.toString(),
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
                    const SizedBox(
                      width: 8,
                    ),
                    SizedBox(
                      width: 140,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 10,
                          ),
                          CustomText(text: widget.model.name.toString()),
                          const SizedBox(
                            height: 2,
                          ),
                          CustomText(
                            text: widget.model.productDetails.packings
                                        .toString()
                                        .length >
                                    15
                                ? "${widget.model.productDetails.packings.toString().substring(0, 15)}..."
                                : widget.model.productDetails.packings
                                    .toString(),
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          CustomText(
                            text:
                                "x ${widget.model.quantity.toString()} ${widget.model.type.toString().toLowerCase() == 'piece' ? 'PCS' : widget.model.type.toString().toUpperCase()}",
                            fontSize: 12,
                            color: FrontendConfigs.kAuthTextColor,
                          ),

                          // PRICE SECTION WITH BULK DISCOUNT
                          if (bulkDiscountValue > 0) ...[
                            // Discounted price
                            CustomText(
                              text: "${finalPrice.toStringAsFixed(2)} Rs",
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: FrontendConfigs.kPrimaryColor,
                            ),
                            // Original price + discount badge
                            Row(
                              children: [
                                Text(
                                  "${originalPrice.toStringAsFixed(2)} Rs",
                                  style: TextStyle(
                                    color: FrontendConfigs.kAuthTextColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: CustomText(
                                    text: cart.getBulkDiscountDisplayText(
                                        widget.model),
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            // Regular price (no bulk discount)
                            CustomText(
                              text: "${finalPrice.toStringAsFixed(2)} Rs",
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: FrontendConfigs.kPrimaryColor,
                            ),
                        ],
                      ),
                    ),
                  ]),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              borderRadius: FrontendConfigs.kAppBorder,
                              onTap: () async {
                                if (widget.model.quantity <= 1) {
                                  cart.removeItem(widget.model.id);
                                } else {
                                  cart.decrement(widget.model.id);
                                }
                              },
                              child: Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                    borderRadius: FrontendConfigs.kAppBorder,
                                    color: widget.model.quantity == 1
                                        ? FrontendConfigs.kTextFieldColor
                                        : Colors.grey),
                                child: Icon(
                                    widget.model.quantity <= 1
                                        ? Icons.delete
                                        : Icons.remove,
                                    color: widget.model.quantity <= 1
                                        ? Colors.red
                                        : Colors.white),
                              ),
                            ),
                            CustomText(
                              text: widget.model.quantity.toString(),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            InkWell(
                              borderRadius: FrontendConfigs.kAppBorder,
                              onTap: () async {
                                cart.increment(
                                    widget.model.id, widget.model.quantity + 1);
                              },
                              child: Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                    borderRadius: FrontendConfigs.kAppBorder,
                                    color: Colors.black),
                                child:
                                    const Icon(Icons.add, color: Colors.white),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )),
      ),
    );
  }
}

void doNothing(BuildContext context) {}
