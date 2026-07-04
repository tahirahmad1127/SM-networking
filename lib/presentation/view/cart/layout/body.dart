import 'package:flutter/material.dart';
import 'package:sm_networking/application/cart_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/configurations/translation_helper.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:sm_networking/presentation/view/check_out/check_out_view.dart';
import 'package:sm_networking/presentation/view/order/no_data_found_view.dart';
import 'package:provider/provider.dart';

import '../../../elements/app_button.dart';
import 'widget/cart_card.dart';

class CartBody extends StatefulWidget {
  const CartBody({super.key});

  @override
  State<CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends State<CartBody> {
  @override
  Widget build(BuildContext context) {
    var cart = Provider.of<CartProvider>(context);
    bool hasBulkDiscount = cart.getTotalBulkDiscount() > 0;

    return SafeArea(
      child: cart.cartItems.isEmpty
          ? const Center(child: NoDataFoundView())
          : Column(
        children: [
          FrontendConfigs.appDivider,
          Expanded(
            child: ListView.builder(
                itemCount: cart.cartItems.length,
                shrinkWrap: true,
                itemBuilder: (context, i) {
                  return CartCard(
                    model: cart.cartItems[i],
                  );
                }),
          ),
          FrontendConfigs.appDivider,
          const SizedBox(
            height: 2,
          ),

          // BULK DISCOUNT SUMMARY (Shows if there's any bulk discount)
          if (hasBulkDiscount)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_offer,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        CustomText(
                          text: "Bulk Discount Applied",
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ],
                    ),
                    CustomText(
                      text:
                      "- ${cart.getTotalBulkDiscount().toStringAsFixed(2)} Rs",
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),

          // TOTAL SECTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Only show "total" label if there's bulk discount
                    if (hasBulkDiscount)
                      CustomText(
                        text: TranslationHelper.getTranslatedText("total"),
                        fontSize: 12,
                        color: FrontendConfigs.kAuthTextColor,
                      ),

                    // Final price (with discount if applicable)
                    CustomText(
                      text: "${cart.getSubTotal().toStringAsFixed(2)} Rs",
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: FrontendConfigs.kPrimaryColor,
                    ),

                    // Show strikethrough price ONLY if there's bulk discount
                    if (hasBulkDiscount)
                      Text(
                        "${cart.getSubTotalWithoutBulkDiscount().toStringAsFixed(2)} Rs",
                        style: TextStyle(
                          fontSize: 12,
                          color: FrontendConfigs.kAuthTextColor,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                AppButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CheckOutView()));
                  },
                  btnLabel: TranslationHelper.getTranslatedText('buy_now'),
                  btnColor: Colors.black,
                  height: 38,
                )
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
        ],
      ),
    );
  }
}