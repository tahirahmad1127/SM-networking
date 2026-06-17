import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sm_networking/application/cart_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:provider/provider.dart';

import '../../../infrastructure/model/all_brands.dart';
import '../cart/cart_view.dart';
import 'layout/body.dart';

class BrandCategoriesView extends StatefulWidget {
  final AllBrandModel brand;
  final bool showCart;

  const BrandCategoriesView({
    super.key,
    required this.brand,
    required this.showCart,
  });

  @override
  State<BrandCategoriesView> createState() => _BrandCategoriesViewState();
}

class _BrandCategoriesViewState extends State<BrandCategoriesView> {
  bool _showSearchBar = false;
  final GlobalKey<BrandCategoriesBodyState> _bodyKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.brand.englishName ?? "Select Products",
          style: FrontendConfigs.kTitleStyle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSearchBar ? Icons.search_off : Icons.search,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() => _showSearchBar = !_showSearchBar);
              // Notify body via its public state key
              _bodyKey.currentState?.setSearchVisible(_showSearchBar);
            },
          ),
          // Scope cart badge rebuilds with Consumer — does NOT rebuild body
          Consumer<CartProvider>(
            builder: (context, cart, _) => Badge(
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
          ),
          const SizedBox(width: 10),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // body stays the same widget instance — no initState re-trigger
      body: BrandCategoriesBody(
        key: _bodyKey,
        brand: widget.brand,
        showCart: widget.showCart,
        showSearchBar: _showSearchBar,
      ),
    );
  }
}