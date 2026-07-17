import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../application/cart_provider.dart';
import '../../../configurations/frontend_configs.dart';
import '../../../infrastructure/model/offline_product.dart';
import '../../../infrastructure/services/offline_cache_service.dart';
import '../../elements/offline_product_card.dart';
import '../../elements/processing_widget.dart';
import '../cart/cart_view.dart';

/// Offline-mode replacement for the Brand → Category → Products navigation
/// chain — a single flat screen listing every cached product, with local
/// (frontend-only) search. Deliberately separate from
/// CategoryListingView/BrandCategoriesView so the online browsing flow is
/// never touched.
class OfflineProductsView extends StatefulWidget {
  const OfflineProductsView({super.key});

  @override
  State<OfflineProductsView> createState() => _OfflineProductsViewState();
}

class _OfflineProductsViewState extends State<OfflineProductsView> {
  bool _loading = true;
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  List<OfflineProductModel> _allProducts = [];
  List<OfflineProductModel> _filtered = [];
  String? _committedSearchTerm;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final products = await OfflineCacheService.getCachedProducts();
    if (!mounted) return;
    setState(() {
      _allProducts = products;
      _filtered = products;
      _loading = false;
    });
  }

  void _onSearchSubmitted(String value) {
    final trimmed = value.trim();
    _committedSearchTerm = trimmed.isEmpty ? null : trimmed;
    setState(() {
      _filtered = _committedSearchTerm == null
          ? _allProducts
          : _allProducts.where((p) {
              final term = _committedSearchTerm!.toLowerCase();
              return p.englishTitle.toLowerCase().contains(term) ||
                  p.urduTitle.toLowerCase().contains(term) ||
                  (p.category?.englishName.toLowerCase().contains(term) ??
                      false) ||
                  (p.brand?.englishName.toLowerCase().contains(term) ?? false);
            }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Products",
          style: TextStyle(color: Colors.black),
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
            onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
          ),
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
      body: _loading
          ? const Center(child: ProcessingWidget())
          : Column(
              children: [
                if (_showSearchBar)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _onSearchSubmitted,
                      decoration: InputDecoration(
                        hintText: 'Search products, press search to look up...',
                        hintStyle:
                            TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: Icon(Icons.search,
                            color: Colors.grey.shade400, size: 20),
                        suffixIcon: _committedSearchTerm != null
                            ? IconButton(
                                icon: Icon(Icons.close,
                                    color: Colors.grey.shade400, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchSubmitted('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: FrontendConfigs.kPrimaryColor
                                  .withOpacity(0.4),
                              width: 1),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: _allProducts.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              "No products cached. Turn Offline Mode off and "
                              "back on while connected to refresh.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : _filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No products match "$_committedSearchTerm"',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final itemWidth =
                                      (constraints.maxWidth - 15) / 2;
                                  return Wrap(
                                    spacing: 15,
                                    runSpacing: 15,
                                    children: _filtered.map((product) {
                                      return SizedBox(
                                        width: itemWidth,
                                        child:
                                            OfflineProductCard(model: product),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
    );
  }
}
