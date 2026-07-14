import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/error.dart';
import 'package:sm_networking/infrastructure/model/product.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:sm_networking/presentation/elements/product_card.dart';
import 'package:sm_networking/presentation/elements/product_details_card.dart';
import 'package:provider/provider.dart';

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

/// Pages through products for one or more categories of [BrandCategoriesBody]'s
/// brand, 10 at a time. The backend only exposes per-category pagination
/// (product/by-brand/{brandId}/category/{categoryId}), not "every category of
/// this brand" in one call — so the "All" chip is served by walking the
/// category queue in order, exhausting each category's pages before moving to
/// the next. A specific category chip is just a queue of one.
class _ProductPager {
  static const int pageSize = 10;

  final Future<Either<GlobalErrorModel, ProductListingModel>> Function({
    required String categoryId,
    required int page,
    required int limit,
    String? searchTerm,
  }) fetchCategoryPage;
  final VoidCallback onChanged;

  _ProductPager({required this.fetchCategoryPage, required this.onChanged});

  final List<ProductModel> items = [];
  bool isInitialLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  String? searchTerm;

  List<String> _queue = [];
  List<String> _lastCategoryIds = [];
  String? _currentCategoryId;
  int _currentPage = 1;
  int _currentTotalPages = 1;
  bool hasMore = true;

  final ScrollController scrollController = ScrollController();

  void attach() => scrollController.addListener(_onScroll);

  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
  }

  void _onScroll() {
    if (isLoadingMore || isInitialLoading || !hasMore) return;
    if (!scrollController.hasClients) return;
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 300) {
      loadMore();
    }
  }

  /// Starts (or restarts) browsing [categoryIds] in order from page 1.
  Future<void> start(List<String> categoryIds, {String? searchTerm}) async {
    _lastCategoryIds = categoryIds;
    _queue = List.of(categoryIds);
    this.searchTerm = searchTerm;
    items.clear();
    errorMessage = null;
    _currentCategoryId = null;
    _currentPage = 1;
    _currentTotalPages = 1;
    hasMore = _queue.isNotEmpty;
    isInitialLoading = true;
    onChanged();
    await loadMore();
  }

  Future<void> refresh() => start(_lastCategoryIds, searchTerm: searchTerm);

  Future<void> loadMore() async {
    if (!hasMore) return;
    isLoadingMore = true;
    onChanged();

    // Keep advancing through the category queue as long as a fetch comes
    // back empty (e.g. a search term with no matches in that particular
    // category) but there's still more queued to check — otherwise a
    // caller expecting "one loadMore() call = visible progress" would see
    // an empty result and stop, even though a later category has matches.
    // No onChanged() inside the loop so the UI doesn't flicker through
    // each empty category — just the final outcome.
    while (true) {
      // Advance to the next queued category once the current one is exhausted.
      if (_currentCategoryId == null || _currentPage > _currentTotalPages) {
        if (_queue.isEmpty) {
          hasMore = false;
          break;
        }
        _currentCategoryId = _queue.removeAt(0);
        _currentPage = 1;
        _currentTotalPages = 1;
      }

      final result = await fetchCategoryPage(
        categoryId: _currentCategoryId!,
        page: _currentPage,
        limit: pageSize,
        searchTerm: searchTerm,
      );

      bool gotItems = false;
      result.fold(
        (l) => errorMessage = l.error.toString(),
        (r) {
          final data = r.data ?? [];
          items.addAll(data);
          _currentTotalPages = r.totalPages ?? 1;
          _currentPage++;
          gotItems = data.isNotEmpty;
        },
      );

      hasMore = _queue.isNotEmpty || _currentPage <= _currentTotalPages;
      if (gotItems || !hasMore) break;
    }

    isInitialLoading = false;
    isLoadingMore = false;
    onChanged();

    // If what we just loaded doesn't fill the viewport, no scroll event
    // will ever fire to trigger the next page/category — without this, a
    // short result set leaves `hasMore` true forever with the trailing
    // "loading more" spinner spinning indefinitely for nothing (this is
    // exactly the "loader stuck in the middle of the screen" glitch).
    // Check once the list has actually rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fillViewportIfNeeded());
  }

  void _fillViewportIfNeeded() {
    if (isLoadingMore || isInitialLoading || !hasMore) return;
    if (!scrollController.hasClients) return;
    if (scrollController.position.maxScrollExtent <= 0) {
      loadMore();
    }
  }
}

class BrandCategoriesBodyState extends State<BrandCategoriesBody> {
  String? _selectedCategoryId;
  bool _isAllSelected = true;

  List<BrandCategoryModel> _categoryList = [];
  bool _categoriesLoading = true;
  String? _categoriesError;

  late final _ProductPager _pager;
  int _loadGeneration = 0;
  bool _disposed = false;

  // ── Search (on-submit only — see TextField's onSubmitted below) ──────────
  final TextEditingController _searchController = TextEditingController();
  String? _committedSearchTerm;

  @override
  void initState() {
    super.initState();
    _pager = _ProductPager(
      onChanged: () {
        if (!_disposed && mounted) setState(() {});
      },
      fetchCategoryPage: ({
        required categoryId,
        required page,
        required limit,
        searchTerm,
      }) {
        return sl<BrandCategoryService>().getProductsByBrandAndCategory(
          brandId: widget.brand.id ?? '',
          categoryID: categoryId,
          page: page,
          limit: limit,
          searchTerm: searchTerm,
        );
      },
    );
    _pager.attach();
    _loadCategoriesThenProducts();
  }

  @override
  void dispose() {
    _disposed = true;
    _loadGeneration++; // invalidates any in-flight async ops
    _searchController.dispose();
    _pager.dispose();
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
    if (mounted) {
      setState(() {
        _categoryList = [];
        _categoriesLoading = true;
        _categoriesError = null;
      });
    }
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
          await _selectCategory(null);
        }
      },
    );
  }

  Future<void> _selectCategory(String? categoryId) async {
    _selectedCategoryId = categoryId;
    _isAllSelected = categoryId == null;
    setState(() {});

    final categoryIds = categoryId != null
        ? [categoryId]
        : _categoryList.map((c) => c.id ?? '').where((id) => id.isNotEmpty).toList();
    await _pager.start(categoryIds, searchTerm: _committedSearchTerm);
  }

  /// Fires only on keyboard-search submit, not on every keystroke.
  void _onSearchSubmitted(String value) {
    final trimmed = value.trim();
    _committedSearchTerm = trimmed.isEmpty ? null : trimmed;
    final categoryIds = _selectedCategoryId != null
        ? [_selectedCategoryId!]
        : _categoryList.map((c) => c.id ?? '').where((id) => id.isNotEmpty).toList();
    _pager.start(categoryIds, searchTerm: _committedSearchTerm);
  }

  @override
  Widget build(BuildContext context) {
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
              textInputAction: TextInputAction.search,
              onSubmitted: _onSearchSubmitted,
              decoration: InputDecoration(
                hintText: 'Search products, press search to look up...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon:
                    Icon(Icons.search, color: Colors.grey.shade400, size: 20),
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
        Expanded(child: _buildGrid()),
      ],
    );
  }

  Widget _buildGrid() {
    if (_pager.isInitialLoading && _pager.items.isEmpty) {
      return const Center(child: ProcessingWidget());
    }
    if (_pager.errorMessage != null && _pager.items.isEmpty) {
      return Center(
        child: Text(
          _pager.errorMessage!,
          style: TextStyle(color: Colors.red.shade400),
        ),
      );
    }
    if (_pager.items.isEmpty) {
      return Center(
        child: Text(
          _committedSearchTerm != null
              ? 'No products match "$_committedSearchTerm"'
              : 'No products found.',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _pager.refresh,
      child: SingleChildScrollView(
        controller: _pager.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 15) / 2;
                return Wrap(
                  spacing: 15,
                  runSpacing: 15,
                  children: _pager.items.map((product) {
                    return SizedBox(
                      width: itemWidth,
                      child: widget.showCart
                          ? ProductCard(
                              model: product,
                              showCtnBox: Provider.of<RetailerProvider>(
                                          context,
                                          listen: false)
                                      .getRetailer()
                                      ?.customerType !=
                                  'distributor',
                            )
                          : ProductDetailsCard(model: product),
                    );
                  }).toList(),
                );
              },
            ),
            // Only while an actual fetch is running — `hasMore` alone can
            // stay true for a long stretch (e.g. more categories still
            // queued for a search) while nothing is happening until the
            // user scrolls further; showing the spinner for that whole
            // idle stretch reads as a stuck/indefinite loader.
            if (_pager.isLoadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
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
