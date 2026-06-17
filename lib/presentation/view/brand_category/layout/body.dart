import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/product.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:sm_networking/presentation/elements/product_card.dart';
import 'package:sm_networking/presentation/elements/product_details_card.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../../../application/user_provider.dart';
import '../../../../../application/retailer_provider.dart';
import '../../../../../injection_container.dart';
import '../../../../infrastructure/model/all_brands.dart';
import '../../../../infrastructure/model/brand_category.dart';
import '../../../../infrastructure/services/brand_category.dart';

class BrandCategoriesBody extends StatefulWidget {
  final AllBrandModel brand;
  final bool showCart;
  final bool showSearchBar;

  const BrandCategoriesBody({
    super.key,
    required this.brand,
    required this.showCart,
    this.showSearchBar = false,
  });

  @override
  State<BrandCategoriesBody> createState() => BrandCategoriesBodyState();
}

class BrandCategoriesBodyState extends State<BrandCategoriesBody> {
  String? _selectedCategoryId;
  bool _isAllSelected = true;

  List<BrandCategoryModel> _categoryList = [];
  bool _categoriesLoading = true;
  String? _categoriesError;

  List<ProductModel> _productList = [];
  bool _productsLoading = false;

  final RefreshController _refreshController =
  RefreshController(initialRefresh: false);
  int _loadGeneration = 0;
  bool _disposed = false;

  // ── Search ────────────────────────────────────────────────────────────────
  // _allProducts holds the full brand product list (all categories combined).
  // _productList is what the grid shows — either _allProducts or filtered.
  List<ProductModel> _allProducts = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<ProductModel> get _displayList {
    final q = _searchQuery.trim().toLowerCase();
    final source = q.isEmpty ? _productList : _allProducts;
    return source.where((p) {
      // ── Hard brand filter — safety net in case API returns cross-brand products
      final brandId = widget.brand.id ?? '';
      if (brandId.isNotEmpty) {
        final productBrandId = p.brand?.id ?? '';
        if (productBrandId.isNotEmpty && productBrandId != brandId) return false;
      }
      // ── Search filter
      if (q.isEmpty) return true;
      final title = (p.englishTitle ?? p.urduTitle ?? '').toLowerCase();
      final pid   = (p.productId ?? '').toLowerCase();
      return title.contains(q) || pid.contains(q);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCategoriesThenProducts();
  }

  @override
  void dispose() {
    _disposed = true;
    _loadGeneration++; // invalidates any in-flight async ops
    _searchController.dispose();
    super.dispose();
  }

  // Called by parent view to toggle search without rebuilding body
  void setSearchVisible(bool visible) {
    if (!_disposed && mounted) {
      setState(() {});
    }
  }

  Future<void> _loadCategoriesThenProducts() async {
    _loadGeneration++;
    final myGen = _loadGeneration;
    if (mounted) setState(() {
      _categoryList = [];
      _productList = [];
      _allProducts = [];
      _categoriesLoading = true;
      _categoriesError = null;
      _productsLoading = false;
    });
    final service = sl<BrandCategoryService>();
    final result = await service.getCategoriesByBrand(widget.brand.id ?? "");
    if (_disposed || !mounted || myGen != _loadGeneration) return;

    result.fold(
          (error) {
        if (!_disposed && mounted && myGen == _loadGeneration) {
          setState(() {
            _categoriesError = error.error.toString();
            _categoriesLoading = false;
          });
        }
      },
          (listing) async {
        if (!_disposed && mounted && myGen == _loadGeneration) {
          final allCats = listing.data ?? [];
          final brandId = widget.brand.id ?? '';
          final filtered = brandId.isEmpty
              ? allCats
              : allCats.where((c) => c.brandIds.contains(brandId)).toList();
          setState(() {
            _categoryList = filtered;
            _categoriesLoading = false;
          });
          await _loadAllProducts(myGen);
        }
      },
    );
  }

  Future<void> _loadAllProducts([int? generation]) async {
    final myGen = generation ?? _loadGeneration;
    if (_categoryList.isEmpty) return;
    if (_disposed || !mounted || myGen != _loadGeneration) return;

    setState(() => _productsLoading = true);

    final service = sl<BrandCategoryService>();
    final futures = _categoryList.map(
            (cat) => service.getProductsByBrandAndCategory(
          brandId: widget.brand.id ?? "",
          categoryID: cat.id ?? "",
          page: 1,
        ));
    final results = await Future.wait(futures);
    if (_disposed || !mounted || myGen != _loadGeneration) return;

    final merged = <ProductModel>[];
    for (int i = 0; i < results.length; i++) {
      if (_disposed || !mounted || myGen != _loadGeneration) return;
      final catId = _categoryList[i].id ?? '';
      results[i].fold(
            (error) => log("Error fetching products: ${error.error}"),
            (listing) {
          for (final product in listing.data ?? []) {
            final productCatId = product.category?.id ?? '';
            final catMatches = catId.isEmpty || productCatId.isEmpty || productCatId == catId;
            if (catMatches && merged.every((p) => p.id != product.id)) {
              merged.add(product);
            }
          }
        },
      );
    }

    if (!_disposed && mounted && myGen == _loadGeneration) {
      setState(() {
        _productList = List.from(merged);
        _allProducts = List.from(merged);
        _productsLoading = false;
      });
      _refreshController.loadComplete();
    }
  }

  Future<void> _selectCategory(String? categoryId) async {
    _selectedCategoryId = categoryId;
    _isAllSelected = categoryId == null;
    // Atomic: clear list + set loading in one setState so grid never shows stale data
    if (mounted) setState(() {
      _productList = [];
      _productsLoading = categoryId != null;
    });

    if (categoryId == null) {
      await _loadAllProducts();
    } else {
      final service = sl<BrandCategoryService>();
      final result = await service.getProductsByBrandAndCategory(
          brandId: widget.brand.id ?? "",
          categoryID: categoryId,
          page: 1);
      result.fold(
            (error) {
          if (mounted) setState(() => _productsLoading = false);
        },
            (listing) {
          if (mounted) {
            // Filter to only products whose category matches the selected tab
            final filtered = (listing.data ?? []).where((p) {
              final productCatId = p.category?.id ?? '';
              return productCatId.isEmpty || productCatId == categoryId;
            }).toList();
            setState(() {
              _productList = filtered;
              _productsLoading = false;
            });
            if (listing.data?.isEmpty ?? true) {
              _refreshController.loadNoData();
            } else {
              _refreshController.loadComplete();
            }
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);

    // While categories are still loading, show a single centered spinner
    if (_categoriesLoading) {
      return const Center(child: ProcessingWidget());
    }

    if (_categoriesError != null) {
      return Center(
        child: Text(
          "Could not load categories",
          style: TextStyle(color: Colors.red.shade400),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 10),

        // ── Category tab bar ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SizedBox(
            height: 30,
            child: ListView.builder(
              itemCount: _categoryList.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                final category = _categoryList[i];
                final isSelected = _selectedCategoryId == category.id;

                return Row(
                  children: [
                    if (i == 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: InkWell(
                          onTap: () => _selectCategory(null),
                          child: _tabChip(
                              label: "All", isSelected: _isAllSelected),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: InkWell(
                        onTap: () => _selectCategory(category.id),
                        child: _tabChip(
                          label: category.englishName ?? "",
                          isSelected: isSelected,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ── Search bar (visible when toggled from AppBar) ─────────────
        if (widget.showSearchBar)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade400, size: 18),
                  onPressed: () => setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  }),
                )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: FrontendConfigs.kPrimaryColor.withOpacity(0.4),
                      width: 1),
                ),
              ),
            ),
          ),

        // ── Product grid ──────────────────────────────────────────────
        Expanded(
          child: _productsLoading
              ? const Center(child: ProcessingWidget())
              : SmartRefresher(
            enablePullDown: false,
            enablePullUp: false,
            controller: _refreshController,
            header: const WaterDropHeader(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _displayList.isEmpty
                  ? Center(
                child: Text(
                  _searchQuery.isNotEmpty
                      ? 'No products match "$_searchQuery"'
                      : 'No products found.',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              )
                  : LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth =
                      (constraints.maxWidth - 15) / 2;
                  return Wrap(
                    spacing: 15,
                    runSpacing: 15,
                    children: _displayList.map((product) {
                      return SizedBox(
                        width: itemWidth,
                        child: widget.showCart
                            ? ProductCard(
                          model: product,
                          showCtnBox: Provider.of<RetailerProvider>(context, listen: false)
                              .getRetailer()
                              ?.customerType != 'distributor',
                        )
                            : ProductDetailsCard(model: product),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabChip({required String label, required bool isSelected}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: FrontendConfigs.kPrimaryColor, width: 1),
        color: isSelected
            ? FrontendConfigs.kPrimaryColor
            : FrontendConfigs.kPrimaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Center(
          child: Text(
            label,
            style: FrontendConfigs.kTitleStyle.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}