import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../application/cart_provider.dart';
import '../../configurations/frontend_configs.dart';
import '../../infrastructure/model/cart.dart';
import '../../infrastructure/model/offline_product.dart';
import '../../infrastructure/model/product.dart';
import 'custom_text.dart';

/// Offline-mode equivalent of ProductCard — deliberately a separate widget
/// so the online card's code path is never touched. No image (the offline
/// bulk-products response doesn't include one); shows category and brand
/// text instead. Cart wiring is identical to ProductCard's — same
/// CartProvider.addItem(CartModel(...)) call.
class OfflineProductCard extends StatefulWidget {
  final OfflineProductModel model;

  const OfflineProductCard({super.key, required this.model});

  @override
  State<OfflineProductCard> createState() => _OfflineProductCardState();
}

class _OfflineProductCardState extends State<OfflineProductCard> {
  TextEditingController cartController = TextEditingController();
  bool isCtnSelected = true;
  bool get _hasCtnBox =>
      widget.model.cortanSize != null && widget.model.piecesPerBox != null;

  @override
  void initState() {
    super.initState();
    final cart = Provider.of<CartProvider>(context, listen: false);
    cartController = TextEditingController(
        text: cart.getItemQuantity(widget.model.id).toString());
  }

  /// The offline response only sends a single flat `price` (no separate
  /// retail/wholesale box rates the way the online ProductModel has) — used
  /// as the box rate directly; carton price is box rate × cortanSize.
  num get _displayPrice {
    final boxRate = widget.model.price;
    if (!_hasCtnBox) return boxRate;
    return isCtnSelected ? boxRate * widget.model.cortanSize! : boxRate;
  }

  ProductModel get _asProductModel => ProductModel(
        id: widget.model.id,
        englishTitle: widget.model.englishTitle,
        urduTitle: widget.model.urduTitle,
        price: widget.model.price,
        cortanSize: widget.model.cortanSize?.toInt(),
        piecesPerBox: widget.model.piecesPerBox?.toInt(),
        image: '',
      );

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final quantity = cart.getItemQuantity(widget.model.id);

    return Container(
      decoration: BoxDecoration(
        borderRadius: FrontendConfigs.kAppBorder,
        color: FrontendConfigs.kTextFieldColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: widget.model.englishTitle,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (widget.model.category != null)
                      CustomText(
                        text: "Category: ${widget.model.category!.englishName}",
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (widget.model.brand != null)
                      CustomText(
                        text: "Brand: ${widget.model.brand!.englishName}",
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Divider(
                      color: FrontendConfigs.kTextFieldColor,
                      thickness: 1,
                      height: 12,
                    ),
                    CustomText(
                      text: "${_displayPrice.toStringAsFixed(2)} Rs",
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: FrontendConfigs.kPrimaryColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 3),
            if (_hasCtnBox)
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      isCtnSelected = true;
                      cart.removeItem(widget.model.id);
                      setState(() {});
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: isCtnSelected
                              ? FrontendConfigs.kPrimaryColor.withOpacity(0.3)
                              : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomLeft: Radius.circular(10),
                          ),
                          border: Border.all(
                              color: isCtnSelected
                                  ? FrontendConfigs.kPrimaryColor
                                  : Colors.grey)),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                        child: Text("Ctn", style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      isCtnSelected = false;
                      cart.removeItem(widget.model.id);
                      setState(() {});
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: !isCtnSelected
                              ? FrontendConfigs.kPrimaryColor.withOpacity(0.3)
                              : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                          border: Border(
                            right: BorderSide(
                                color: !isCtnSelected
                                    ? FrontendConfigs.kPrimaryColor
                                    : Colors.grey),
                            top: BorderSide(
                                color: !isCtnSelected
                                    ? FrontendConfigs.kPrimaryColor
                                    : Colors.grey),
                            bottom: BorderSide(
                                color: !isCtnSelected
                                    ? FrontendConfigs.kPrimaryColor
                                    : Colors.grey),
                          )),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8.0, vertical: 5),
                        child: Text("Box", style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  ),
                ],
              ),
            SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: quantity < 1
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.spaceBetween,
                children: [
                  if (quantity >= 1)
                    InkWell(
                      borderRadius: FrontendConfigs.kAppBorder,
                      onTap: () {
                        if (quantity <= 1) {
                          cart.removeItem(widget.model.id);
                        } else {
                          cart.decrement(widget.model.id);
                          cartController = TextEditingController(
                              text: (quantity - 1).toString());
                        }
                        setState(() {});
                      },
                      child: Container(
                        height: 35,
                        width: 35,
                        decoration: BoxDecoration(
                            borderRadius: FrontendConfigs.kAppBorder,
                            color: quantity == 1
                                ? FrontendConfigs.kTextFieldColor
                                : Colors.grey),
                        child: Icon(quantity <= 1 ? Icons.delete : Icons.remove,
                            color: quantity <= 1 ? Colors.red : Colors.white),
                      ),
                    ),
                  if (quantity >= 1)
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
                                name: widget.model.englishTitle,
                                id: widget.model.id,
                                price: _displayPrice.toStringAsFixed(2),
                                image: '',
                                offer: false,
                                productDetails: _asProductModel,
                                quantity: entered,
                                totalQuantity: 0,
                                type: isCtnSelected ? "ctn" : "pcs"));
                            setState(() {});
                          },
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              border: UnderlineInputBorder(
                                  borderSide: BorderSide.none)),
                        ),
                      ),
                    ),
                  InkWell(
                    borderRadius: FrontendConfigs.kAppBorder,
                    onTap: () {
                      final currentQty = cart.getItemQuantity(widget.model.id);
                      cart.addItem(CartModel(
                          name: widget.model.englishTitle,
                          id: widget.model.id,
                          price: _displayPrice.toStringAsFixed(2),
                          image: '',
                          offer: false,
                          productDetails: _asProductModel,
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
