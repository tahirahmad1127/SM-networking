import 'dart:developer';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sm_networking/application/cart_provider.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:provider/provider.dart';
import '../../application/retailer_provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../infrastructure/model/cart.dart';
import '../../infrastructure/model/product.dart';

class ProductCard extends StatefulWidget {
  final ProductModel model;

  /// Show Ctn/Box toggle when the selected customer is a wholesaler or retailer.
  /// Pass true for both orderBooker AND warehouseManager when visiting a
  /// wholesaler or retailer. Pass false (default) for distributor visits.
  final bool showCtnBox;

  const ProductCard({super.key, required this.model, this.showCtnBox = false});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool isEnabled = true;

  TextEditingController cartController = TextEditingController();

  /// Front-end-only price override, set via the edit-price dialog. When
  /// null, the computed _displayPrice() is used as-is.
  num? _customPrice;

  @override
  void initState() {
    var cart = Provider.of<CartProvider>(context, listen: false);
    cartController = TextEditingController(
        text: cart.getItemQuantity(widget.model.id.toString()).toString());
    super.initState();
  }

  bool isCtnSelected = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // TSM always orders by carton — lock to Ctn (default already true)
    // orderBooker sees the toggle and can switch freely
  }

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<UserProvider>(context);
    var cart = Provider.of<CartProvider>(context);

    return InkWell(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          borderRadius: FrontendConfigs.kAppBorder,
          color: FrontendConfigs.kTextFieldColor,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: (widget.model.bulkDiscount != null &&
                      widget.model.bulkDiscount!.isNotEmpty)
                  ? 4
                  : 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.model.bulkDiscount != null &&
                  widget.model.bulkDiscount!.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    context.showBulkDiscountDialog(widget.model);
                  },
                  child: Container(
                    height: 16,
                    width: 100,
                    decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            topRight: Radius.circular(6),
                            bottomLeft: Radius.circular(6),
                            bottomRight: Radius.circular(6)),
                        color: FrontendConfigs.kPrimaryColor),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(6),
                              bottomLeft: Radius.circular(6),
                              bottomRight: Radius.circular(6)),
                        ),
                        child: Center(
                            child: CustomText(
                          text: "Bulk Discount",
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        )),
                      ),
                    ),
                  ),
                ),

              ExtendedImage.network(
                widget.model.image.toString(),
                height: 80,
                width: double.infinity,
                fit: BoxFit.fill,
                cache: true,
                loadStateChanged: (ExtendedImageState state) {
                  switch (state.extendedImageLoadState) {
                    case LoadState.loading:
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 27.0, horizontal: 10),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Image.asset(
                            "assets/images/karyana.png",
                            fit: BoxFit.fill,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    case LoadState.failed:
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 27.0, horizontal: 10),
                        child: Image.asset(
                          "assets/images/karyana.png",
                          fit: BoxFit.fill,
                          color: Colors.grey[350],
                        ),
                      );
                    default:
                      return state.completedWidget;
                  }
                },
                borderRadius: const BorderRadius.all(Radius.circular(30.0)),
              ),
              const SizedBox(height: 2),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: widget.model.englishTitle.toString(),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      CustomText(
                        text: widget.model.packings.toString(),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: Colors.grey,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Divider(
                        color: FrontendConfigs.kTextFieldColor,
                        thickness: 1,
                        height: 0,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () => _showEditPriceDialog(context),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CustomText(
                                      text:
                                          "${_effectivePrice(context).toStringAsFixed(2)} Rs",
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: FrontendConfigs.kPrimaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.edit,
                                      size: 14,
                                      color: FrontendConfigs.kPrimaryColor
                                          .withOpacity(0.6),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 3),

              ///____________Cotton/Packet Row — hidden for orderBooker (Pcs only)
              if (widget.showCtnBox)
                Row(
                  children: [
                    //________Cotton Selected
                    InkWell(
                      onTap: () {
                        log("Cotton Selected");
                        isCtnSelected = true;
                        _customPrice = null;
                        cart.removeItem(widget.model.id.toString());
                        setState(() {});
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: isCtnSelected == true
                                ? FrontendConfigs.kPrimaryColor.withOpacity(0.3)
                                : Colors.transparent,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                            border: Border.all(
                                color: isCtnSelected == true
                                    ? FrontendConfigs.kPrimaryColor
                                    : Colors.grey)),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 5),
                          child: Text("Ctn", style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                    //________Packet Selected
                    InkWell(
                      onTap: () {
                        log("Packet Selected");
                        isCtnSelected = false;
                        _customPrice = null;
                        cart.removeItem(widget.model.id.toString());
                        setState(() {});
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            color: isCtnSelected == true
                                ? Colors.transparent
                                : FrontendConfigs.kPrimaryColor
                                    .withOpacity(0.3),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                            border: Border(
                              right: BorderSide(
                                  color: isCtnSelected == false
                                      ? FrontendConfigs.kPrimaryColor
                                      : Colors.grey),
                              top: BorderSide(
                                  color: isCtnSelected == false
                                      ? FrontendConfigs.kPrimaryColor
                                      : Colors.grey),
                              bottom: BorderSide(
                                  color: isCtnSelected == false
                                      ? FrontendConfigs.kPrimaryColor
                                      : Colors.grey),
                            )),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 5),
                          child: Text("Box", style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),

              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment:
                      cart.getItemQuantity(widget.model.id.toString()) < 1
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.spaceBetween,
                  children: [
                    if (cart.getItemQuantity(widget.model.id.toString()) >= 1)
                      InkWell(
                        borderRadius: FrontendConfigs.kAppBorder,
                        onTap: () async {
                          if (cart.getItemQuantity(
                                  widget.model.id.toString()) <=
                              1) {
                            cart.removeItem(widget.model.id.toString());
                          } else {
                            cart.decrement(widget.model.id.toString());
                            cartController = TextEditingController(
                                text: (cart.getItemQuantity(
                                            widget.model.id.toString()) -
                                        1)
                                    .toString());
                          }
                          setState(() {});
                        },
                        child: Container(
                          height: 35,
                          width: 35,
                          decoration: BoxDecoration(
                              borderRadius: FrontendConfigs.kAppBorder,
                              color: cart.getItemQuantity(
                                          widget.model.id.toString()) ==
                                      1
                                  ? FrontendConfigs.kTextFieldColor
                                  : Colors.grey),
                          child: Icon(
                              cart.getItemQuantity(
                                          widget.model.id.toString()) <=
                                      1
                                  ? Icons.delete
                                  : Icons.remove,
                              color: cart.getItemQuantity(
                                          widget.model.id.toString()) <=
                                      1
                                  ? Colors.red
                                  : Colors.white),
                        ),
                      ),
                    if (cart.getItemQuantity(widget.model.id.toString()) >= 1)
                      Expanded(
                          child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: TextField(
                          textAlign: TextAlign.center,
                          controller: cartController,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (val) {
                            if (val.isEmpty) return;
                            final entered = int.tryParse(val) ?? 0;
                            cart.addItem(CartModel(
                                name: widget.model.englishTitle.toString(),
                                id: widget.model.id.toString(),
                                price:
                                    _effectivePrice(context).toStringAsFixed(2),
                                image: widget.model.image.toString(),
                                offer: widget.model.isDiscounted ?? false,
                                productDetails: widget.model,
                                quantity: entered,
                                totalQuantity: 0,
                                type: isCtnSelected ? "ctn" : "pcs"));
                            log(cart
                                .getItemQuantity(widget.model.id.toString())
                                .toString());
                            setState(() {});
                          },
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              border: UnderlineInputBorder(
                                  borderSide: BorderSide.none)),
                        ),
                      )),
                    InkWell(
                      borderRadius: FrontendConfigs.kAppBorder,
                      onTap: () async {
                        final currentQty =
                            cart.getItemQuantity(widget.model.id.toString());
                        cart.addItem(CartModel(
                            name: widget.model.englishTitle.toString(),
                            id: widget.model.id.toString(),
                            price: _effectivePrice(context).toStringAsFixed(2),
                            image: widget.model.image.toString(),
                            offer: widget.model.isDiscounted ?? false,
                            productDetails: widget.model,
                            quantity: currentQty + 1,
                            totalQuantity: 0,
                            type: isCtnSelected ? "ctn" : "pcs"));
                        cartController = TextEditingController(
                            text: (currentQty + 1).toString());
                        setState(() {});
                      },
                      child: Container(
                        height: 35,
                        width: 35,
                        decoration: BoxDecoration(
                            borderRadius: FrontendConfigs.kAppBorder,
                            color: Colors.black),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Price helper ─────────────────────────────────────────────────────────────
  // Rules:
  //   Box price = retailSaleRatePerBox  (retailer)
  //             = wholesaleRatePerBox   (wholesaler or distributor)
  //   Ctn price = boxPrice × piecesPerBox
  //   Distributor always shows wholesale carton price (no toggle).
  num _displayPrice(BuildContext context) {
    final p = widget.model;
    final customerType = Provider.of<RetailerProvider>(context, listen: false)
            .getRetailer()
            ?.customerType ??
        'wholesaler';

    final num ratePerBox = (customerType == 'retailer')
        ? (p.retailSaleRatePerBox ?? p.wholesaleRatePerBox ?? p.price ?? 0)
        : (p.wholesaleRatePerBox ?? p.price ?? 0);

    // cortanSize = number of boxes per carton (e.g. 24)
    // piecesPerBox = pieces inside each box (e.g. 150) — NOT used for carton price
    final int boxesPerCarton = p.cortanSize ?? 1;

    // Distributor (showCtnBox = false) always shows carton price
    if (!widget.showCtnBox) return ratePerBox * boxesPerCarton;

    return isCtnSelected ? ratePerBox * boxesPerCarton : ratePerBox;
  }

  /// The price actually used for display and for cart/order totals — the
  /// manually-entered override if one has been set via the edit-price
  /// dialog, otherwise the normal computed price.
  num _effectivePrice(BuildContext context) {
    return _customPrice ?? _displayPrice(context);
  }

  /// Front-end-only price override. Does not call any API and does not
  /// change the backend's actual product price — only what this specific
  /// order charges for this item.
  void _showEditPriceDialog(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final currentPrice = _effectivePrice(context);
    final controller = TextEditingController(
        text: currentPrice.toStringAsFixed(
            currentPrice.truncateToDouble() == currentPrice ? 0 : 2));

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Edit Price"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "This only changes the rate for this order. It does not "
                "change the product's actual price.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(
                  prefixText: "Rs ",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text("Save"),
              onPressed: () {
                final entered = num.tryParse(controller.text.trim());
                if (entered == null || entered <= 0) {
                  getFlushBar(context, title: "Enter a valid price.");
                  return;
                }
                Navigator.of(dialogContext).pop();
                setState(() => _customPrice = entered);

                // If this item is already sitting in the cart, addItem()
                // alone won't update its price (it falls through to
                // increment(), which only touches quantity) — so update
                // the existing entry directly.
                if (cart.getItemQuantity(widget.model.id.toString()) >= 1) {
                  cart.updateItemPrice(
                    widget.model.id.toString(),
                    entered.toStringAsFixed(2),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

/// Bulk Discount Dialog
class BulkDiscountDialog extends StatelessWidget {
  final ProductModel product;

  const BulkDiscountDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (product.bulkDiscount == null ||
        product.bulkDiscount!.isEmpty ||
        product.bulkDiscountQuantity == null ||
        product.bulkDiscountQuantity!.isEmpty) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, size: 40, color: Colors.grey),
              const SizedBox(height: 10),
              CustomText(
                text: "No bulk discounts available",
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: screenWidth,
        constraints: const BoxConstraints(maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: FrontendConfigs.kPrimaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.discount_rounded,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomText(
                      text: "Bulk Discount Offers",
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Subtitle
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: FrontendConfigs.kPrimaryColor.withOpacity(0.1),
              child: CustomText(
                text: "Add more quantity to get higher discounts",
                fontSize: 12,
                color: FrontendConfigs.kPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Discount Cards
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                itemCount: product.bulkDiscount!.length,
                itemBuilder: (context, index) {
                  final quantity = product.bulkDiscountQuantity![index];
                  final discount = product.bulkDiscount![index];
                  final type = product.bulkDiscountType != null &&
                          index < product.bulkDiscountType!.length
                      ? product.bulkDiscountType![index]
                      : "Flat";

                  final originalPrice = product.price ?? 0;
                  final isPercentage = type.toLowerCase() == "percentage";
                  final discountedPricePerPiece = isPercentage
                      ? originalPrice - (originalPrice * discount / 100)
                      : originalPrice;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: FrontendConfigs.kPrimaryColor.withOpacity(0.3),
                        width: 1.2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: FrontendConfigs.kPrimaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              children: [
                                CustomText(
                                  text: "$quantity+",
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: FrontendConfigs.kPrimaryColor,
                                ),
                                const SizedBox(height: 2),
                                CustomText(
                                  text: "Ctns",
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: FrontendConfigs.kPrimaryColor,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isPercentage) ...[
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      CustomText(
                                        text:
                                            "PKR ${discountedPricePerPiece.toStringAsFixed(0)}",
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: FrontendConfigs.kPrimaryColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "PKR ${originalPrice.toStringAsFixed(0)}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: CustomText(
                                      text: "$discount% OFF per piece",
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ] else ...[
                                  CustomText(
                                    text:
                                        "PKR ${originalPrice.toStringAsFixed(0)} per piece",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2D3142),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: CustomText(
                                      text: "PKR $discount OFF on total",
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Info Footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 6),
                  Expanded(
                    child: CustomText(
                      text:
                          "Each carton contains ${product.cortanSize} pieces. Percentage discounts apply per piece, flat discounts apply to total order.",
                      fontSize: 10,
                      color: Colors.blue.shade700,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension BulkDiscountDialogExtension on BuildContext {
  void showBulkDiscountDialog(ProductModel product) {
    showDialog(
      context: this,
      builder: (context) => BulkDiscountDialog(product: product),
    );
  }
}
