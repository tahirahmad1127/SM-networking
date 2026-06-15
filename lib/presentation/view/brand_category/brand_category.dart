import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sm_networking/application/cart_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:provider/provider.dart';

import '../../../infrastructure/model/all_brands.dart';
import '../cart/cart_view.dart';
import 'layout/body.dart';

class BrandCategoriesView extends StatelessWidget {
  final AllBrandModel brand;
  final bool showCart;

  const BrandCategoriesView({
    super.key,
    required this.brand,
    required this.showCart,
  });

  @override
  Widget build(BuildContext context) {
    var cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          brand.englishName ?? "Select Products",
          style: FrontendConfigs.kTitleStyle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Badge(
            isLabelVisible: cart.cartItems.isNotEmpty,
            alignment: const AlignmentDirectional(0.5, -0.5),
            label: Text(cart.cartItems.length.toString()),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartView()),
                );
              },
              icon: const Icon(CupertinoIcons.cart, color: Colors.black),
            ),
          ),
          const SizedBox(width: 10),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BrandCategoriesBody(brand: brand, showCart: showCart),
    );
  }
}