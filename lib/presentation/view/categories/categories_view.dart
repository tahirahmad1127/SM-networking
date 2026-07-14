import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sm_networking/application/cart_provider.dart';
import 'package:sm_networking/presentation/view/categories/layout/body.dart';
import 'package:provider/provider.dart';

import '../../../configurations/frontend_configs.dart';
import '../../../infrastructure/model/category.dart';
import '../cart/cart_view.dart';

class CategoriesView extends StatelessWidget {
  final bool showCart;

  const CategoriesView(
      {super.key, required this.model, required this.showCart});
  final CategoryModel model;

  @override
  Widget build(BuildContext context) {
    var cart = Provider.of<CartProvider>(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Select Products",
          style: FrontendConfigs.kTitleStyle,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          // IconButton(
          //     onPressed: () {
          //       Navigator.pop(context);
          //     },
          //     icon: const Icon(
          //       Icons.change_circle_outlined,
          //       color: Colors.black,
          //     )),
          Badge(
            isLabelVisible: cart.cartItems.isNotEmpty,
            alignment: const AlignmentDirectional(0.5, -0.5),
            label: Text(cart.cartItems.length.toString()),
            child: IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CartView()));
                },
                icon: const Icon(
                  CupertinoIcons.cart,
                  color: Colors.black,
                )),
          ),
          SizedBox(
            width: 10,
          )
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: CategoriesBody(model: model, showCart: showCart),
    );
  }
}
