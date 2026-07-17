import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dartz/dartz.dart' hide State;
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sm_networking/application/locaition_helper.dart';
import 'package:sm_networking/application/offline_mode_provider.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/error.dart';
import 'package:sm_networking/infrastructure/model/retailer.dart';
import 'package:sm_networking/infrastructure/model/user.dart';
import 'package:sm_networking/infrastructure/services/order_booker_activity.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:sm_networking/presentation/view/category_listing/category_listing_view.dart';
import 'package:sm_networking/presentation/view/offline_products/offline_products_view.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../application/location.dart';
import '../../../application/retailer_bloc/retailer_bloc.dart';
import '../../../application/retailer_provider.dart';
import '../../../application/search_providers.dart';
import '../../../application/visit_bloc/visit_bloc.dart';
import '../../../application/visit_provider.dart';
import '../../../infrastructure/model/visit.dart';
import '../../../infrastructure/services/offline_cache_service.dart';
import '../../../infrastructure/services/offline_visit_image_store.dart';
import '../../../infrastructure/services/retailer.dart';
import '../../../injection_container.dart';
import '../../elements/animated_search.dart';
import '../../elements/flush_bar.dart';
import '../../elements/my_logger.dart';
import '../../elements/navigation_dialog.dart';
import '../add_recovery/add_recovery.dart';
import '../map/widget/visit_bottomsheet_widget.dart';
import '../order/no_data_found_view.dart';

// ── Paginated tab state ─────────────────────────────────────────────────────
//
// One instance per tab (Distributors / Wholesalers / Retailers). Owns its
// own scroll position, search box, and loaded page — so switching tabs never
// loses where you were, and search is scoped to whichever tab is active.
// Mirrors the pattern already used in orderbooker_recoveries_view.dart.
class _Page<T> {
  final List<T> data;
  final int page;
  final int totalPages;
  final int total;

  const _Page({
    required this.data,
    required this.page,
    required this.totalPages,
    required this.total,
  });
}

class _PaginatedTabState<T> {
  static const int pageSize = 15;

  final Future<Either<GlobalErrorModel, _Page<T>>> Function(
      {required int page, required int limit, String? searchTerm}) fetchPage;
  final VoidCallback onChanged;

  _PaginatedTabState({required this.fetchPage, required this.onChanged});

  final List<T> items = [];
  int page = 1;
  int totalPages = 1;
  int total = 0;
  bool isInitialLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  String? searchTerm;
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  void attach() => scrollController.addListener(_onScroll);

  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    searchController.dispose();
  }

  void _onScroll() {
    if (isLoadingMore || isInitialLoading) return;
    if (page >= totalPages) return;
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      loadNextPage();
    }
  }

  // Set as soon as a load is kicked off (not when it completes) so this tab
  // is only ever fetched once — callers (initial-active-tab load, and
  // lazy load-on-tab-switch) don't need to coordinate with each other.
  bool hasLoadedOnce = false;

  Future<void> loadFirstPage() {
    if (hasLoadedOnce) return Future.value();
    hasLoadedOnce = true;
    return _fetch(page: 1, replace: true);
  }

  /// Pull-to-refresh — deliberately does NOT clear [items] first, so the old
  /// list stays visible under RefreshIndicator's own spinner instead of
  /// flashing to a blank/loading screen.
  Future<void> refresh() => _fetch(page: 1, replace: true);

  Future<void> loadNextPage() async {
    isLoadingMore = true;
    onChanged();
    await _fetch(page: page + 1, replace: false);
  }

  /// Called on keyboard-search submit (not on every keystroke). Unlike
  /// [refresh], this clears the old (now-irrelevant) results and shows the
  /// full loading spinner immediately — otherwise the stale list from
  /// before the search just sits there with zero feedback while the
  /// request is in flight, which is exactly what looked like a stuck app.
  Future<void> submitSearch(String value) {
    final trimmed = value.trim();
    searchTerm = trimmed.isEmpty ? null : trimmed;
    items.clear();
    isInitialLoading = true;
    onChanged();
    return _fetch(page: 1, replace: true);
  }

  Future<void> _fetch({required int page, required bool replace}) async {
    if (replace) errorMessage = null;
    onChanged();

    final result =
        await fetchPage(page: page, limit: pageSize, searchTerm: searchTerm);

    result.fold(
      (l) {
        errorMessage = l.error.toString();
        if (replace) items.clear();
      },
      (r) {
        if (replace) items.clear();
        items.addAll(r.data);
        this.page = r.page;
        totalPages = r.totalPages;
        total = r.total;
      },
    );

    isInitialLoading = false;
    isLoadingMore = false;
    onChanged();

    // If the page(s) loaded so far don't fill the viewport, no scroll event
    // will ever fire to trigger the next page — without this, a short
    // result set (e.g. a search match found on only 1-2 items) leaves
    // `page < totalPages` true forever with the trailing "loading more"
    // spinner spinning indefinitely for nothing. Check once the list has
    // actually rendered, and keep pulling pages until it either fills the
    // viewport or genuinely runs out.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fillViewportIfNeeded());
  }

  void _fillViewportIfNeeded() {
    if (isLoadingMore || isInitialLoading) return;
    if (page >= totalPages) return;
    if (!scrollController.hasClients) return;
    if (scrollController.position.maxScrollExtent <= 0) {
      loadNextPage();
    }
  }
}

class RetailersView extends StatefulWidget {
  const RetailersView({super.key});

  @override
  State<RetailersView> createState() => _RetailersViewState();
}

class _RetailersViewState extends State<RetailersView>
    with TickerProviderStateMixin {
  LatLng? myLocation;
  LatLng? currentLocation;

  // Tab controller — 3 tabs for warehouseManager, 2 for orderBooker
  late TabController _tabController;
  String _tabRole = ''; // tracks which role the controller was built for

  // ── Retailer search (legacy retailer-bloc view — non-TSM/orderBooker roles) ──
  List<RetailerModel> searchUser = [];
  bool isSearchingAllow = false;
  bool isSearched = false;

  final Set<String> _updatingLocationIds = {};

  // Covers the gap between picking a visit image and the brands screen
  // appearing (GPS fetch + visitProvider.setStartVisit) — otherwise the
  // screen just sits there with no feedback for that stretch.
  bool _isStartingOrder = false;

  // ── Paginated tabs — warehouseManager sees Distributors/Wholesalers/
  // Retailers, orderBooker sees Wholesalers/Retailers. Each tab owns its own
  // scroll position, page, and on-submit search box (see _PaginatedTabState).
  late final _PaginatedTabState<Distributor> _distributorsTab;
  late final _PaginatedTabState<Wholesaler> _wholesalersTab;
  late final _PaginatedTabState<Wholesaler> _retailersTab;

  // ── Town filter (warehouseManager) ──
  // The town of whichever distributor is currently checked in, per the
  // same 'wm_dist_{distributorId}' SharedPreferences state that
  // warehouse_attendence_body.dart writes on check-in/check-out. Null
  // means either the role isn't warehouseManager, or nobody is currently
  // checked into any distributor — in both cases we fall back to showing
  // the unfiltered lists rather than an empty screen.
  String? _activeTownId;

  // The framework calls didChangeDependencies right after initState, before
  // _initPaginatedTabs' own async town resolution has settled — letting its
  // refresh-on-town-change logic run there too would race the initial load
  // and always look like a "change" (from unset to resolved), firing a
  // redundant duplicate fetch for wholesalers/retailers. Skip that logic on
  // this very first call; _initPaginatedTabs already covers the initial load.
  bool _isFirstDependenciesChange = true;

  Future<void> _resolveActiveTownId() async {
    if (!mounted) return;
    final user = Provider.of<UserProvider>(context, listen: false);
    final distributors = user.getSalesUserDetails()?.distributors ?? [];
    final prefs = await SharedPreferences.getInstance();

    String? foundTownId;
    for (final d in distributors) {
      final id = (d.id ?? d.salesId ?? '').trim();
      if (id.isEmpty) continue;
      final raw = prefs.getString('wm_dist_$id');
      if (raw == null) continue;
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final checkOutTime = decoded['checkOutTime'];
        final isCheckedIn = checkOutTime == null ||
            (checkOutTime is String && checkOutTime.isEmpty);
        if (isCheckedIn) {
          foundTownId = d.town?.id;
          break;
        }
      } catch (_) {}
    }

    if (mounted) setState(() => _activeTownId = foundTownId);
  }

  void _searchData(String val) async {
    searchUser.clear();
    var search = Provider.of<SearchProviders>(context, listen: false);
    for (var i in search.getRetailerList) {
      var lowerCaseString =
          i.shopName.toString().toLowerCase() + i.name.toString().toLowerCase();
      var defaultCase = i.shopName.toString() + i.name.toString();
      if (lowerCaseString.contains(val) || defaultCase.contains(val)) {
        isSearched = true;
        searchUser.add(i);
      } else {
        isSearched = true;
      }
      setState(() {});
    }
  }

  /// Builds the three paginated tabs. Called once — each tab's fetchPage
  /// closure re-reads UserProvider/_activeTownId fresh on every call, so it
  /// always uses the latest token/role/town filter without needing to be
  /// rebuilt.
  void _initPaginatedTabs() {
    _distributorsTab = _PaginatedTabState<Distributor>(
      onChanged: () {
        if (mounted) setState(() {});
      },
      fetchPage: ({required page, required limit, searchTerm}) async {
        if (Provider.of<OfflineModeProvider>(context, listen: false).isOffline) {
          final all = await OfflineCacheService.getCachedDistributors();
          final filtered = searchTerm == null || searchTerm.isEmpty
              ? all
              : all
                  .where((d) =>
                      (d.distributionName ?? '')
                          .toLowerCase()
                          .contains(searchTerm.toLowerCase()) ||
                      (d.name ?? '')
                          .toLowerCase()
                          .contains(searchTerm.toLowerCase()) ||
                      (d.phone ?? '')
                          .toLowerCase()
                          .contains(searchTerm.toLowerCase()))
                  .toList();
          return Right(_Page(
              data: filtered, page: 1, totalPages: 1, total: filtered.length));
        }
        final details =
            Provider.of<UserProvider>(context, listen: false).getSalesUserDetails();
        final tsmId = details?.user?.id ?? '';
        final token = details?.token ?? '';
        final result = await OrderBookerActivityRepositoryImp().getDistributorsForTsm(
          tsmId: tsmId,
          page: page,
          limit: limit,
          searchTerm: searchTerm,
          token: token,
        );
        return result.map((r) => _Page(
            data: r.data, page: r.page, totalPages: r.totalPages, total: r.total));
      },
    );

    _wholesalersTab = _PaginatedTabState<Wholesaler>(
      onChanged: () {
        if (mounted) setState(() {});
      },
      fetchPage: ({required page, required limit, searchTerm}) async {
        if (Provider.of<OfflineModeProvider>(context, listen: false).isOffline) {
          final all = await OfflineCacheService.getCachedWholesalers();
          final filtered = searchTerm == null || searchTerm.isEmpty
              ? all
              : all
                  .where((w) =>
                      (w.name ?? '')
                          .toLowerCase()
                          .contains(searchTerm.toLowerCase()) ||
                      (w.contacts ?? '')
                          .toLowerCase()
                          .contains(searchTerm.toLowerCase()) ||
                      (w.address ?? '')
                          .toLowerCase()
                          .contains(searchTerm.toLowerCase()))
                  .toList();
          return Right(_Page(
              data: filtered, page: 1, totalPages: 1, total: filtered.length));
        }
        final details =
            Provider.of<UserProvider>(context, listen: false).getSalesUserDetails();
        final token = details?.token ?? '';
        final isWarehouseManager = details?.role == 'warehouseManager';
        final result = await RetailerRepositoryImp().getWholesalersPaginated(
          page: page,
          limit: limit,
          searchTerm: searchTerm,
          town: isWarehouseManager ? _activeTownId : null,
          lat: currentLocation?.latitude,
          lng: currentLocation?.longitude,
          token: token,
        );
        return result.map((r) => _Page(
            data: r.data, page: r.page, totalPages: r.totalPages, total: r.total));
      },
    );

    _retailersTab = _PaginatedTabState<Wholesaler>(
      onChanged: () {
        if (mounted) setState(() {});
      },
      fetchPage: ({required page, required limit, searchTerm}) async {
        if (Provider.of<OfflineModeProvider>(context, listen: false).isOffline) {
          final all = await OfflineCacheService.getCachedRetailers();
          final filtered = searchTerm == null || searchTerm.isEmpty
              ? all
              : all
                  .where((w) =>
                      (w.name ?? '')
                          .toLowerCase()
                          .contains(searchTerm.toLowerCase()) ||
                      (w.contacts ?? '')
                          .toLowerCase()
                          .contains(searchTerm.toLowerCase()) ||
                      (w.address ?? '')
                          .toLowerCase()
                          .contains(searchTerm.toLowerCase()))
                  .toList();
          return Right(_Page(
              data: filtered, page: 1, totalPages: 1, total: filtered.length));
        }
        final details =
            Provider.of<UserProvider>(context, listen: false).getSalesUserDetails();
        final token = details?.token ?? '';
        final isWarehouseManager = details?.role == 'warehouseManager';
        final result = await RetailerRepositoryImp().getRetailersPaginated(
          page: page,
          limit: limit,
          searchTerm: searchTerm,
          town: isWarehouseManager ? _activeTownId : null,
          lat: currentLocation?.latitude,
          lng: currentLocation?.longitude,
          token: token,
        );
        return result.map((r) => _Page(
            data: r.data, page: r.page, totalPages: r.totalPages, total: r.total));
      },
    );

    _distributorsTab.attach();
    _wholesalersTab.attach();
    _retailersTab.attach();

    final role =
        Provider.of<UserProvider>(context, listen: false).getSalesUserDetails()?.role ?? '';

    // Resolve the checked-in-distributor town filter before the first fetch
    // so whichever tab loads first is already scoped to it, when applicable.
    // Only the tab that's actually visible by default (index 0) loads here —
    // the others load lazily the first time the user switches to them (see
    // _handleTabChange), so opening "View All" doesn't pay for three API
    // calls up front when the user only wants to look at one tab.
    _resolveActiveTownId().then((_) {
      if (!mounted) return;
      if (role == 'warehouseManager') {
        _distributorsTab.loadFirstPage();
      } else if (role == 'orderBooker') {
        _wholesalersTab.loadFirstPage();
      }
    });
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    final index = _tabController.index;
    if (_tabRole == 'warehouseManager') {
      if (index == 1) _wholesalersTab.loadFirstPage();
      if (index == 2) _retailersTab.loadFirstPage();
    } else if (_tabRole == 'orderBooker') {
      if (index == 1) _retailersTab.loadFirstPage();
    }
  }

  @override
  void initState() {
    super.initState();
    // Default length 2; will be rebuilt in build() when role is known
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _initPaginatedTabs();
    determinePosition().then((value) {
      if (!mounted) return;
      setState(() {
        myLocation = LatLng(value.latitude, value.longitude);
        currentLocation = LatLng(value.latitude, value.longitude);
      });
    }).catchError((Object e) {
      log(e.toString());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final cached =
            Provider.of<LocationProvider>(context, listen: false).getLatLng();
        setState(() {
          myLocation = cached ?? const LatLng(24.8607, 67.0011);
          currentLocation = myLocation;
        });
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _distributorsTab.dispose();
    _wholesalersTab.dispose();
    _retailersTab.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Re-resolve the checked-in-distributor town filter on every dependency
    // change after the first (covers check-in/out elsewhere, and logout ->
    // login), and refresh the wholesaler/retailer tabs if it actually
    // changed. The very first call is skipped — _initPaginatedTabs already
    // handles the initial load with the resolved town, so re-checking here
    // too would just duplicate that fetch.
    if (_isFirstDependenciesChange) {
      _isFirstDependenciesChange = false;
    } else {
      final previousTownId = _activeTownId;
      _resolveActiveTownId().then((_) {
        if (!mounted || _activeTownId == previousTownId) return;
        _wholesalersTab.refresh();
        _retailersTab.refresh();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      if (visitProvider.startVisit == null) {
        visitProvider.stopLocationMonitoring();
        AppLogger.debug("🛑 Stopped VisitProvider timer on return to map");
      }
    });
  }

  Future<void> _refreshCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      log("Error refreshing location: $e");
      getFlushBar(context, title: "Could not get current location");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final search = Provider.of<SearchProviders>(context);

    // Session can be cleared out from under this screen mid-build (forced
    // logout on a 401) — several branches below assume a non-null user
    // (e.g. the legacy retailer-bloc view's zone lookup), so bail out to a
    // harmless placeholder for that one frame instead of crashing.
    if (user.getSalesUserDetails()?.user == null) {
      return const SizedBox.shrink();
    }

    final role = user.getSalesUserDetails()?.role ?? '';
    final isOrderBooker = role == 'orderBooker';
    final isWarehouseManager = role == 'warehouseManager';
    final hasThreeTabs = isWarehouseManager;
    final showTabs = isOrderBooker || isWarehouseManager;

    // ── Rebuild TabController if role changed ──
    final neededLength = hasThreeTabs ? 3 : 2;
    if (_tabRole != role || _tabController.length != neededLength) {
      _tabController.dispose();
      _tabController = TabController(length: neededLength, vsync: this);
      _tabController.addListener(_handleTabChange);
      _tabRole = role;
    }

    // ── AppBar title ──
    final appBarTitle = isOrderBooker
        ? 'Wholesalers/Retailers'
        : isWarehouseManager
            ? 'Customers'
            : 'Distributors';

    // ── Search handler — on-submit only (keyboard search key), routes to
    // whichever tab is currently active. Empty query clears that tab's
    // search filter and reloads it unfiltered.
    void handleSearch(String query) {
      if (isWarehouseManager) {
        final idx = _tabController.index;
        if (idx == 0) {
          _distributorsTab.submitSearch(query);
        } else if (idx == 1) {
          _wholesalersTab.submitSearch(query);
        } else {
          _retailersTab.submitSearch(query);
        }
      } else if (isOrderBooker) {
        if (_tabController.index == 0) {
          _wholesalersTab.submitSearch(query);
        } else {
          _retailersTab.submitSearch(query);
        }
      } else {
        isSearchingAllow = query.isNotEmpty;
        _searchData(query);
      }
    }

    // ── Tab definitions ──
    final tabBar = showTabs
        ? Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: FrontendConfigs.kPrimaryColor,
              unselectedLabelColor: FrontendConfigs.kAuthTextColor,
              indicatorColor: FrontendConfigs.kPrimaryColor,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: isWarehouseManager
                  ? const [
                      Tab(text: "Distributors"),
                      Tab(text: "Wholesalers"),
                      Tab(text: "Retailers"),
                    ]
                  : const [
                      Tab(text: "Wholesalers"),
                      Tab(text: "Retailers"),
                    ],
            ),
          )
        : null;

    final scaffold = Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          showTabs ? kToolbarHeight + kTextTabBarHeight : kToolbarHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSearchAppBar(
              title: appBarTitle,
              onCancel: () {
                isSearchingAllow = false;
                searchUser.clear();
                if (isWarehouseManager) {
                  _distributorsTab.submitSearch('');
                  _wholesalersTab.submitSearch('');
                  _retailersTab.submitSearch('');
                } else if (isOrderBooker) {
                  _wholesalersTab.submitSearch('');
                  _retailersTab.submitSearch('');
                }
                setState(() {});
              },
              onSearch: handleSearch,
            ),
            if (tabBar != null) tabBar,
          ],
        ),
      ),
      body: myLocation == null
          ? const Center(child: ProcessingWidget())
          : isWarehouseManager
              // ── warehouseManager: 3 tabs ──
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDistributorTab(context, _distributorsTab),
                    _buildWholesalerTab(
                      context,
                      _wholesalersTab,
                      emptyMessage: "No wholesalers found.",
                      heading: "Wholesalers",
                      isRetailer: false,
                    ),
                    _buildWholesalerTab(
                      context,
                      _retailersTab,
                      emptyMessage: "No retailers found.",
                      heading: "Retailers",
                      isRetailer: true,
                    ),
                  ],
                )
              : isOrderBooker
                  // ── orderBooker: 2 tabs ──
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        _buildWholesalerTab(
                          context,
                          _wholesalersTab,
                          emptyMessage: "No wholesalers found.",
                          heading: "Wholesalers",
                          isRetailer: false,
                        ),
                        _buildWholesalerTab(
                          context,
                          _retailersTab,
                          emptyMessage: "No retailers found.",
                          heading: "Retailers",
                          isRetailer: true,
                        ),
                      ],
                    )
                  // ── other roles (TSM): original retailer BLoC flow ──
                  : _buildRetailerBlocView(context, user, search),
    );

    return Stack(
      children: [
        scaffold,
        if (_isStartingOrder)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: ProcessingWidget()),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Paginated infinite-scroll list — shared shape for Wholesalers/Retailers
  // and Distributors tabs (see _buildDistributorTab below).
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWholesalerTab(
    BuildContext context,
    _PaginatedTabState<Wholesaler> tab, {
    required String emptyMessage,
    required String heading,
    bool isRetailer = false,
  }) {
    if (tab.isInitialLoading && tab.items.isEmpty) {
      return const Center(child: ProcessingWidget());
    }
    if (tab.errorMessage != null && tab.items.isEmpty) {
      return Center(child: Text(tab.errorMessage!));
    }
    if (tab.items.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    // Only while an actual fetch is running — `page < totalPages` alone can
    // stay true for a long stretch while nothing is happening until the
    // user scrolls further; showing the spinner for that whole idle
    // stretch reads as a stuck/indefinite loader.
    final showMoreLoader = tab.isLoadingMore;
    return RefreshIndicator(
      onRefresh: tab.refresh,
      child: ListView.builder(
        controller: tab.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: tab.items.length + 1 + (showMoreLoader ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                "$heading (${tab.total})",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: FrontendConfigs.kAuthTextColor,
                ),
              ),
            );
          }
          if (i > tab.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _buildWholesalerCard(context, tab.items[i - 1],
              isRetailer: isRetailer);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Distributor tab — warehouseManager only
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDistributorTab(
    BuildContext context,
    _PaginatedTabState<Distributor> tab,
  ) {
    if (tab.isInitialLoading && tab.items.isEmpty) {
      return const Center(child: ProcessingWidget());
    }
    if (tab.errorMessage != null && tab.items.isEmpty) {
      return Center(child: Text(tab.errorMessage!));
    }
    if (tab.items.isEmpty) {
      return const Center(child: Text("No distributors found."));
    }

    // Only while an actual fetch is running — `page < totalPages` alone can
    // stay true for a long stretch while nothing is happening until the
    // user scrolls further; showing the spinner for that whole idle
    // stretch reads as a stuck/indefinite loader.
    final showMoreLoader = tab.isLoadingMore;
    return RefreshIndicator(
      onRefresh: tab.refresh,
      child: ListView.builder(
        controller: tab.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: tab.items.length + 1 + (showMoreLoader ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                "Distributors (${tab.total})",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: FrontendConfigs.kAuthTextColor,
                ),
              ),
            );
          }
          if (i > tab.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _buildDistributorCard(context, tab.items[i - 1]);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Original retailer BLoC view (unchanged for non-distributor roles)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildRetailerBlocView(
    BuildContext context,
    UserProvider user,
    SearchProviders search,
  ) {
    return BlocProvider(
      create: (context) => sl<RetailerBloc>(),
      child: BlocListener<RetailerBloc, RetailerState>(
        listener: (context, state) {
          if (state is RetailerLocationUpdated) {
            getFlushBar(context, title: "Location updated successfully!");
            BlocProvider.of<RetailerBloc>(context).add(
              GetRetailerEvent(
                  user.getSalesUserDetails()!.user!.zone.toString()),
            );
          } else if (state is RetailerFailed) {
            getFlushBar(context, title: state.message);
          }
        },
        child: BlocBuilder<RetailerBloc, RetailerState>(
          builder: (context, state) {
            if (state is RetailerInitial) {
              BlocProvider.of<RetailerBloc>(context).add(GetRetailerEvent(
                  user.getSalesUserDetails()!.user!.zone.toString()));
              return const Center(child: ProcessingWidget());
            } else if (state is RetailerLoading) {
              return const Center(child: ProcessingWidget());
            } else if (state is RetailerLoaded) {
              List<RetailerModel> retailerList = [];
              search.saveRetailerList(state.model.data!);
              retailerList = state.model.data!.map((e) {
                return RetailerModel(
                  createdAt: e.createdAt,
                  docId: e.id,
                  id: e.id,
                  isUnderProcessed: e.isUnderProcessed,
                  image: e.image,
                  isActive: e.isActive,
                  isVerified: e.isVerified,
                  lat: e.lat,
                  lng: e.lng,
                  name: e.name,
                  phoneNumber: e.phoneNumber,
                  shopAddress1: e.shopAddress1,
                  shopAddress2: e.shopAddress2,
                  shopCategory: e.shopCategory,
                  shopName: e.shopName,
                  cnicBack: e.cnicBack,
                  cnicFront: e.cnicFront,
                  customerType:
                      e.customerType.isNotEmpty ? e.customerType : 'retailer',
                  distance: calculateDistance(
                      start: myLocation!,
                      end: LatLng(e.lat!.toDouble(), e.lng!.toDouble())),
                );
              }).toList();
              retailerList.sort((a, b) => a.distance!.compareTo(b.distance!));

              if (searchUser.isEmpty && isSearchingAllow == true) {
                return const Center(child: NoDataFoundView());
              } else {
                final customerList =
                    searchUser.isEmpty ? retailerList : searchUser;

                return customerList.isNotEmpty
                    ? customerList[0].docId == null
                        ? SizedBox(
                            height: MediaQuery.of(context).size.height * 0.7,
                            child: const Center(child: ProcessingWidget()),
                          )
                        : ListView.builder(
                            itemCount: customerList.length,
                            itemBuilder: (context, i) {
                              return _buildRetailerCard(
                                  context, customerList[i]);
                            },
                          )
                    : const Center(
                        child: Text(
                            "Sorry! We cannot find any shop related to your search."),
                      );
              }
            } else if (state is RetailerFailed) {
              return Center(child: Text(state.message.toString()));
            } else {
              return const Center(child: Text("Something went wrong"));
            }
          },
        ),
      ),
    );
  }

  Future<void> _commitDistributorLocationUpdate(
      Distributor d, double lat, double lng) async {
    // Use MongoDB ObjectId (_id) — NOT salesId (numeric string)
    final id = (d.id ?? d.salesId ?? '').trim();
    if (id.isEmpty) {
      if (mounted) {
        getFlushBar(context, title: 'Missing distributor id');
      }
      return;
    }
    final userProvider = context.read<UserProvider>();
    final token = userProvider.getSalesUserDetails()?.token ?? '';
    if (token.isEmpty) {
      if (mounted) {
        getFlushBar(context, title: 'Session expired. Please log in again.');
      }
      return;
    }
    // Calls sale-user/location/{id} — the correct distributor endpoint
    final result = await RetailerRepositoryImp().updateDistributorLocation(
      distributorId: id,
      lat: lat,
      lng: lng,
      token: token,
    );
    if (!mounted) return;
    result.fold(
      (l) => getFlushBar(context, title: l.error.toString()),
      (_) {
        userProvider.patchDistributorShopLocation(id, lat, lng);
        setState(() {
          currentLocation = LatLng(lat, lng);
        });
        getFlushBar(context, title: 'Location updated successfully');
      },
    );
  }

  Future<void> _commitWholesalerLocationUpdate(
      Wholesaler w, double lat, double lng) async {
    final id = (w.id ?? '').trim();
    if (id.isEmpty) {
      if (mounted) {
        getFlushBar(context, title: 'Missing wholesaler/retailer id');
      }
      return;
    }
    final userProvider = context.read<UserProvider>();
    final token = userProvider.getSalesUserDetails()?.token ?? '';
    if (token.isEmpty) {
      if (mounted) {
        getFlushBar(context, title: 'Session expired. Please log in again.');
      }
      return;
    }
    final result = await RetailerRepositoryImp().updateWholesalerLocation(
      wholesalerId: id,
      lat: lat,
      lng: lng,
      token: token,
    );
    if (!mounted) return;
    result.fold(
      (l) => getFlushBar(context, title: l.error.toString()),
      (updated) {
        userProvider.patchWholesalerShopLocation(id, lat, lng,
            address: updated.address);
        setState(() {
          currentLocation = LatLng(lat, lng);
        });
        getFlushBar(context, title: 'Location updated successfully');
      },
    );
  }

  Future<void> _commitRetailerLocationUpdate(
      Wholesaler w, double lat, double lng) async {
    final id = (w.id ?? '').trim();
    if (id.isEmpty) {
      if (mounted) {
        getFlushBar(context, title: 'Missing retailer id');
      }
      return;
    }
    final userProvider = context.read<UserProvider>();
    final token = userProvider.getSalesUserDetails()?.token ?? '';
    if (token.isEmpty) {
      if (mounted) {
        getFlushBar(context, title: 'Session expired. Please log in again.');
      }
      return;
    }
    final result = await RetailerRepositoryImp().updateRetailerLocation(
      retailerId: id,
      lat: lat,
      lng: lng,
      token: token,
    );
    if (!mounted) return;
    result.fold(
      (l) => getFlushBar(context, title: l.error.toString()),
      (updated) {
        userProvider.patchRetailerShopLocation(id, lat, lng,
            address: updated.shopAddress1);
        setState(() {
          currentLocation = LatLng(lat, lng);
        });
        getFlushBar(context, title: 'Location updated successfully');
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared "Start Order / Start Booking" flow.
  // Opens the visit bottom sheet, starts visit + auto-log monitoring, then
  // saves the mapped RetailerModel and navigates to CategoryListingView.
  // Used by distributor "Company Order", wholesaler/retailer "Market Booking".
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _startOrderFlow(RetailerModel asRetailer) async {
    if (currentLocation == null) {
      getFlushBar(context, title: "Current location not available");
      return;
    }

    await showVisitBottomSheet(context, (selectedImage) async {
      if (mounted) setState(() => _isStartingOrder = true);
      try {
        await _runStartOrderFlow(asRetailer, selectedImage);
      } finally {
        if (mounted) setState(() => _isStartingOrder = false);
      }
    });
  }

  Future<void> _runStartOrderFlow(
      RetailerModel asRetailer, File? selectedImage) async {
    final visitProvider = Provider.of<VisitProvider>(context, listen: false);
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    var imagePath = selectedImage?.path;

    // Offline Mode: copy the picked image into a persistent app directory
    // so it survives until the user syncs (the picker's default path is an
    // OS-purgeable cache dir, risky for a file that might sit for hours).
    if (imagePath != null &&
        Provider.of<OfflineModeProvider>(context, listen: false).isOffline) {
      imagePath = await persistVisitImageIfOffline(imagePath);
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    AppLogger.debug("📍 Initial GPS location obtained");
    AppLogger.debug(
        "   Location: ${position.latitude}, ${position.longitude}");
    AppLogger.debug("   Accuracy: ${position.accuracy.toStringAsFixed(2)}m");

    await visitProvider.setStartVisit(
      location: currentLocation!,
      imagePath: imagePath,
      accuracy: position.accuracy,
      onLocationCheckCallback: () async {
        if (visitProvider.startVisit == null ||
            visitProvider.visitLocation == null) {
          AppLogger.debug("⚠️ Visit data cleared - skipping callback");
          return;
        }

        Position freshPosition;
        try {
          freshPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
          AppLogger.debug("📍 Fresh GPS location obtained in timer callback");
          log("   Location: ${freshPosition.latitude}, ${freshPosition.longitude}");
          log("   Accuracy: ${freshPosition.accuracy.toStringAsFixed(2)}m");
        } catch (e) {
          AppLogger.debug("❌ Failed to get fresh GPS location: $e");
          return;
        }

        final currentLoc =
            LatLng(freshPosition.latitude, freshPosition.longitude);
        locationProvider.setLatLng(currentLoc);

        await visitProvider.checkAndAutoLogVisit(
          currentLocation: currentLoc,
          currentAccuracy: freshPosition.accuracy,
          onShowNotification: (message) {
            if (context.mounted) {
              getFlushBar(context, title: message);
            }
          },
          onAutoLogVisit: () async {
            if (visitProvider.startVisit == null) {
              AppLogger.debug("⚠️ Visit cleared before auto-log");
              return;
            }

            final retailerProvider =
                Provider.of<RetailerProvider>(context, listen: false);
            final userProvider =
                Provider.of<UserProvider>(context, listen: false);
            final selectedRetailer = retailerProvider.getRetailer();
            final userDetails = userProvider.getSalesUserDetails()?.user;
            final startVisit = await visitProvider.getStartVisit();

            if (selectedRetailer != null &&
                userDetails != null &&
                startVisit != null) {
              final visit = VisitModel(
                retailerId: selectedRetailer.id.toString(),
                salesPersonId: userDetails.id.toString(),
                startTime: startVisit.toIso8601String(),
                endTime: DateTime.now().toIso8601String(),
                date: DateTime.now().toString().split(' ')[0],
                image: visitProvider.visitImage ?? "",
              );

              if (context.mounted) {
                context.read<VisitBloc>().add(AddVisitEvent(visit));
                await visitProvider.clearVisitData();
                AppLogger.debug(
                    "✅ Visit auto-logged via background monitoring");
              }
            }
          },
        );
      },
    );

    Provider.of<RetailerProvider>(context, listen: false)
        .saveRetailer(asRetailer);

    final isOffline =
        Provider.of<OfflineModeProvider>(context, listen: false).isOffline;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => isOffline
            ? const OfflineProductsView()
            : const CategoryListingView(showCart: true),
      ),
    );

    if (mounted) {
      getFlushBar(context, title: "Visit Started Successfully");
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Long-press handlers — trigger the "update to current location" flow that
  // used to live on the map-icon button. Each shows the same confirmation
  // dialog, then commits via the existing per-type update methods.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _handleDistributorLongPress(
      Distributor d, String displayName) async {
    final idKey = d.id ?? d.salesId ?? '';
    if (_updatingLocationIds.contains(idKey)) return;
    await _refreshCurrentLocation();
    if (currentLocation == null) {
      getFlushBar(context, title: "Current location not available");
      return;
    }
    await showNavigationDialog(
      context,
      message: "Update $displayName's location to your current location?",
      buttonText: "Update",
      navigation: () async {
        Navigator.of(context).pop();
        setState(() => _updatingLocationIds.add(idKey));
        getFlushBar(context, title: "Updating location...");
        try {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          if (!mounted) return;
          setState(() {
            currentLocation = LatLng(pos.latitude, pos.longitude);
          });
          await _commitDistributorLocationUpdate(
              d, pos.latitude, pos.longitude);
        } catch (e) {
          if (mounted) {
            getFlushBar(context, title: e.toString());
          }
        } finally {
          if (mounted) setState(() => _updatingLocationIds.remove(idKey));
        }
      },
      secondButtonText: "Cancel",
      showSecondButton: true,
    );
  }

  Future<void> _handleWholesalerLongPress(
      Wholesaler w, String displayName, bool isRetailer) async {
    if (_updatingLocationIds.contains(w.id)) return;
    await _refreshCurrentLocation();
    if (currentLocation == null) {
      getFlushBar(context, title: "Current location not available");
      return;
    }
    await showNavigationDialog(
      context,
      message: "Update $displayName's location to your current location?",
      buttonText: "Update",
      navigation: () async {
        Navigator.of(context).pop();
        setState(() => _updatingLocationIds.add(w.id ?? ''));
        getFlushBar(context, title: "Updating location...");
        try {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          if (!mounted) return;
          setState(() {
            currentLocation = LatLng(pos.latitude, pos.longitude);
          });
          if (isRetailer) {
            await _commitRetailerLocationUpdate(w, pos.latitude, pos.longitude);
          } else {
            await _commitWholesalerLocationUpdate(
                w, pos.latitude, pos.longitude);
          }
        } catch (e) {
          if (mounted) {
            getFlushBar(context, title: e.toString());
          }
        } finally {
          if (mounted) setState(() => _updatingLocationIds.remove(w.id ?? ''));
        }
      },
      secondButtonText: "Cancel",
      showSecondButton: true,
    );
  }

  Future<void> _handleRetailerCardLongPress(
      RetailerModel currentRetailer) async {
    await _refreshCurrentLocation();
    if (currentLocation == null) {
      getFlushBar(context, title: "Current location not available");
      return;
    }
    await showNavigationDialog(
      context,
      message:
          "Update ${currentRetailer.shopName}'s location to your current location?",
      buttonText: "Update",
      navigation: () async {
        final token =
            context.read<UserProvider>().getSalesUserDetails()?.token ?? '';
        if (token.isEmpty) {
          getFlushBar(context, title: 'Session expired. Please log in again.');
          Navigator.pop(context);
          return;
        }
        BlocProvider.of<RetailerBloc>(context).add(UpdateRetailerLocationEvent(
          retailerId: currentRetailer.id.toString(),
          lat: currentLocation!.latitude,
          lng: currentLocation!.longitude,
          token: token,
        ));
        Navigator.pop(context);
      },
      secondButtonText: "Cancel",
      showSecondButton: true,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper: resolve a valid shipping address from a Distributor
  // Tries: address → town name → distributionName → name → "N/A"
  // ─────────────────────────────────────────────────────────────────────────
  String _resolveDistributorAddress(Distributor d) {
    final address = d.address?.trim() ?? '';
    if (address.isNotEmpty) return address;

    final town = d.town?.name?.trim() ?? '';
    if (town.isNotEmpty) return town;

    final distName = d.distributionName?.trim() ?? '';
    if (distName.isNotEmpty) return distName;

    return d.name?.trim().isNotEmpty == true ? d.name! : 'N/A';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Distributor vertical card (warehouseManager / orderBooker list items)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDistributorCard(BuildContext context, Distributor d) {
    final displayName = (d.distributionName?.isNotEmpty == true)
        ? d.distributionName!
        : (d.name ?? '—');
    final phone = d.phone ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5),
      child: GestureDetector(
        onLongPress: () => _handleDistributorLongPress(d, displayName),
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            borderRadius: FrontendConfigs.kAppBorder,
            color: FrontendConfigs.kTextFieldColor,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar (display only — tap the cart button to start an order)
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      FrontendConfigs.kPrimaryColor.withOpacity(0.12),
                  child: ClipOval(
                    child: (d.image != null && d.image!.isNotEmpty)
                        ? ExtendedImage.network(
                            d.image!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            cache: true,
                            loadStateChanged: (ExtendedImageState state) {
                              switch (state.extendedImageLoadState) {
                                case LoadState.loading:
                                case LoadState.failed:
                                  return Center(
                                    child: Text(
                                      (d.name?.isNotEmpty == true
                                              ? d.name![0]
                                              : 'D')
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: FrontendConfigs.kPrimaryColor,
                                      ),
                                    ),
                                  );
                                default:
                                  return state.completedWidget;
                              }
                            },
                          )
                        : Center(
                            child: Text(
                              (d.name?.isNotEmpty == true ? d.name![0] : 'D')
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: FrontendConfigs.kPrimaryColor,
                              ),
                            ),
                          ),
                  ),
                ),

                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (d.name?.isNotEmpty == true) ...[
                        const SizedBox(height: 5),
                        Text(
                          d.name!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          phone,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                      if (_distributorsTab.searchTerm == null &&
                          myLocation != null &&
                          d.shopLocation?.lat != null &&
                          d.shopLocation?.lng != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          "Distance: ${calculateDistance(start: myLocation!, end: LatLng(d.shopLocation!.lat!.toDouble(), d.shopLocation!.lng!.toDouble())).toStringAsFixed(2)} km(s) away",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: FrontendConfigs.kAuthTextColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Action buttons column
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Start Company Order (long-press the tile to update location instead)
                    InkWell(
                      onTap: () {
                        final resolvedAddress = _resolveDistributorAddress(d);
                        final asRetailer = RetailerModel(
                          id: d.id ?? d.salesId,
                          docId: d.id ?? d.salesId,
                          name: d.name,
                          shopName: d.distributionName ?? d.name,
                          shopAddress1: resolvedAddress,
                          phoneNumber: d.phone,
                          lat: d.shopLocation?.lat,
                          lng: d.shopLocation?.lng,
                          image: d.image ?? '',
                          isActive: d.isActive,
                          customerType: 'distributor',
                        );
                        _startOrderFlow(asRetailer);
                      },
                      child: Container(
                        height: 35,
                        width: 35,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: FrontendConfigs.kPrimaryColor,
                        ),
                        child: const Icon(CupertinoIcons.cart_fill,
                            color: Colors.white, size: 18),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Add Recovery
                    InkWell(
                      onTap: () {
                        if (Provider.of<OfflineModeProvider>(context,
                                listen: false)
                            .isOffline) {
                          getFlushBar(context,
                              title:
                                  "Add Recovery requires an internet connection.");
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddRecoveryView(
                              distributorId: d.id ?? d.salesId ?? '',
                              paymentType: 'distributor',
                              customerType: '',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 35,
                        width: 35,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: FrontendConfigs.kPrimaryColor,
                        ),
                        child: const Icon(
                            CupertinoIcons.money_dollar_circle_fill,
                            color: Colors.white,
                            size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Wholesaler / Retailer card (orderBooker list items) ─────────────────
  Widget _buildWholesalerCard(BuildContext context, Wholesaler w,
      {bool isRetailer = false}) {
    final displayName = w.name ?? '—';
    final phone = w.contacts ?? '';
    final address = w.address ?? '';
    final townName = w.town?.name ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5),
      child: GestureDetector(
        onLongPress: () =>
            _handleWholesalerLongPress(w, displayName, isRetailer),
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            borderRadius: FrontendConfigs.kAppBorder,
            color: FrontendConfigs.kTextFieldColor,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      FrontendConfigs.kPrimaryColor.withOpacity(0.15),
                  child: Text(
                    (w.name?.isNotEmpty == true ? w.name![0] : 'W')
                        .toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: FrontendConfigs.kPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(phone, style: const TextStyle(fontSize: 13)),
                      ],
                      if (townName.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(CupertinoIcons.map_pin,
                                size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Text(
                              townName,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          address,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Action buttons column
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Start Market Booking (long-press the tile to update location instead)
                    InkWell(
                      onTap: () {
                        final asRetailer = RetailerModel(
                          id: w.id,
                          docId: w.id,
                          name: w.name,
                          shopName: w.name,
                          shopAddress1: w.address,
                          phoneNumber: w.contacts,
                          lat: w.shopLocation?.lat ?? w.addressFromGoogle?.lat,
                          lng: w.shopLocation?.lng ?? w.addressFromGoogle?.lng,
                          image: w.pic ?? '',
                          isActive: w.isActive,
                          customerType: isRetailer ? 'retailer' : 'wholesaler',
                        );
                        _startOrderFlow(asRetailer);
                      },
                      child: Container(
                        height: 35,
                        width: 35,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: FrontendConfigs.kPrimaryColor,
                        ),
                        child: const Icon(CupertinoIcons.cart_fill,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Add Recovery
                    InkWell(
                      onTap: () {
                        if (Provider.of<OfflineModeProvider>(context,
                                listen: false)
                            .isOffline) {
                          getFlushBar(context,
                              title:
                                  "Add Recovery requires an internet connection.");
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddRecoveryView(
                              distributorId: w.id ?? '',
                              paymentType: 'market_recovery',
                              customerType:
                                  isRetailer ? 'retailer' : 'wholesaler',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 35,
                        width: 35,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: FrontendConfigs.kPrimaryColor,
                        ),
                        child: const Icon(
                            CupertinoIcons.money_dollar_circle_fill,
                            color: Colors.white,
                            size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Original retailer card (unchanged) ────────────────────────────────────
  Widget _buildRetailerCard(
      BuildContext context, RetailerModel currentRetailer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5),
      child: InkWell(
        onTap: () => _startOrderFlow(currentRetailer),
        onLongPress: () => _handleRetailerCardLongPress(currentRetailer),
        child: Container(
          height: 135,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            borderRadius: FrontendConfigs.kAppBorder,
            color: FrontendConfigs.kTextFieldColor,
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ExtendedImage.network(
                  currentRetailer.image.toString(),
                  height: 100,
                  width: 90,
                  fit: BoxFit.fill,
                  cacheHeight: 200,
                  cacheWidth: 200,
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
                        return Image.asset(
                          "assets/images/ph.jpg",
                          fit: BoxFit.cover,
                          height: 120,
                          width: 120,
                        );
                      default:
                        return state.completedWidget;
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentRetailer.shopName.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                Text(currentRetailer.name.toString()),
                                const SizedBox(height: 5),
                                Text(currentRetailer.phoneNumber.toString()),
                                const SizedBox(height: 5),
                                if (isSearchingAllow != true)
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.6,
                                    child: Text(
                                      "Distance: ${currentRetailer.distance!.toStringAsFixed(2)} km(s) away",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: FrontendConfigs.kAuthTextColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            children: [
                              // Start Order (long-press the tile to update location instead)
                              InkWell(
                                onTap: () => _startOrderFlow(currentRetailer),
                                child: Container(
                                  height: 35,
                                  width: 35,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: FrontendConfigs.kPrimaryColor,
                                  ),
                                  child: const Icon(CupertinoIcons.cart_fill,
                                      color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () {
                                  if (Provider.of<OfflineModeProvider>(context,
                                          listen: false)
                                      .isOffline) {
                                    getFlushBar(context,
                                        title:
                                            "Add Recovery requires an internet connection.");
                                    return;
                                  }
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddRecoveryView(
                                        distributorId:
                                            currentRetailer.id?.toString() ??
                                                '',
                                        paymentType: 'market_recovery',
                                        customerType: 'retailer',
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: 35,
                                  width: 35,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: FrontendConfigs.kPrimaryColor,
                                  ),
                                  child: const Icon(
                                      CupertinoIcons.money_dollar_circle_fill,
                                      color: Colors.white),
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
            ],
          ),
        ),
      ),
    );
  }

  num calculateDistance({required LatLng start, required LatLng end}) {
    var distanceInMeters = Geolocator.distanceBetween(
        start.latitude, start.longitude, end.latitude, end.longitude);
    return (distanceInMeters / 1000);
  }
}
