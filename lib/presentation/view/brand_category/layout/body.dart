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

  const BrandCategoriesBody({
    super.key,
    required this.brand,
    required this.showCart,
  });

  @override
  State<BrandCategoriesBody> createState() => _BrandCategoriesBodyState();
}

class _BrandCategoriesBodyState extends State<BrandCategoriesBody> {
  String? _selectedCategoryId;
  bool _isAllSelected = true;

  List<BrandCategoryModel> _categoryList = [];
  bool _categoriesLoading = true;
  String? _categoriesError;

  final List<ProductModel> _productList = [];
  bool _productsLoading = false;

  final RefreshController _refreshController =
  RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    _loadCategoriesThenProducts();
  }

  Future<void> _loadCategoriesThenProducts() async {
    final service = sl<BrandCategoryService>();
    final result = await service.getCategoriesByBrand(widget.brand.id ?? "");

    result.fold(
          (error) {
        if (mounted) {
          setState(() {
            _categoriesError = error.error.toString();
            _categoriesLoading = false;
          });
        }
      },
          (listing) async {
        if (mounted) {
          // Filter to only categories that include this brand in their brandIds list.
          final allCats = listing.data ?? [];
          final brandId = widget.brand.id ?? '';
          final filtered = brandId.isEmpty
              ? allCats
              : allCats
              .where((c) => c.brandIds.contains(brandId))
              .toList();
          setState(() {
            _categoryList = filtered;
            _categoriesLoading = false;
          });
          await _loadAllProducts();
        }
      },
    );
  }

  Future<void> _loadAllProducts() async {
    if (_categoryList.isEmpty) return;

    if (mounted) setState(() => _productsLoading = true);

    final service = sl<BrandCategoryService>();
    final futures = _categoryList.map(
            (cat) => service.getProductsByBrandAndCategory(
          brandId: widget.brand.id ?? "",
          categoryID: cat.id ?? "",
          page: 1,
        ));
    final results = await Future.wait(futures);

    final merged = <ProductModel>[];
    for (final result in results) {
      result.fold(
            (error) => log("Error fetching products: ${error.error}"),
            (listing) {
          for (final product in listing.data ?? []) {
            if (merged.every((p) => p.id != product.id)) {
              merged.add(product);
            }
          }
        },
      );
    }

    if (mounted) {
      setState(() {
        _productList.clear();
        _productList.addAll(merged);
        _productsLoading = false;
      });
      _refreshController.loadComplete();
    }
  }

  Future<void> _selectCategory(String? categoryId) async {
    _selectedCategoryId = categoryId;
    _isAllSelected = categoryId == null;
    _productList.clear();
    setState(() {});

    if (categoryId == null) {
      await _loadAllProducts();
    } else {
      if (mounted) setState(() => _productsLoading = true);
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
            setState(() {
              _productList.addAll(listing.data ?? []);
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

        const SizedBox(height: 20),

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
              child: _productList.isEmpty
                  ? const Center(child: Text("No products found."))
                  : LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth =
                      (constraints.maxWidth - 15) / 2;
                  return Wrap(
                    spacing: 15,
                    runSpacing: 15,
                    children: _productList.map((product) {
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