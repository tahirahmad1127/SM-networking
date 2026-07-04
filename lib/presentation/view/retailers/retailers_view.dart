import 'dart:developer';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sm_networking/application/locaition_helper.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/retailer.dart';
import 'package:sm_networking/infrastructure/model/user.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:sm_networking/presentation/view/category_listing/category_listing_view.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../application/location.dart';
import '../../../application/retailer_bloc/retailer_bloc.dart';
import '../../../application/retailer_provider.dart';
import '../../../application/search_providers.dart';
import '../../../application/visit_bloc/visit_bloc.dart';
import '../../../application/visit_provider.dart';
import '../../../infrastructure/model/visit.dart';
import '../../../infrastructure/services/retailer.dart';
import '../../../injection_container.dart';
import '../../elements/animated_search.dart';
import '../../elements/flush_bar.dart';
import '../../elements/my_logger.dart';
import '../../elements/navigation_dialog.dart';
import '../add_recovery/add_recovery.dart';
import '../map/widget/visit_bottomsheet_widget.dart';
import '../order/no_data_found_view.dart';

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

  // ── Retailer search (non-distributor roles) ──
  List<RetailerModel> searchUser = [];
  bool isSearchingAllow = false;
  bool isSearched = false;

  // ── Distributor search (warehouseManager) ──
  List<Distributor> searchDistributors = [];
  bool isDistributorSearching = false;

  // ── Distributor fetch state (warehouseManager) ──
  List<Distributor> _fetchedDistributors = [];
  bool _distributorsLoading = false;
  String? _distributorsError;

  // ── Wholesaler / Retailer search (orderBooker AND warehouseManager) ──
  List<Wholesaler> searchWholesalers = [];
  List<Wholesaler> searchRetailers = [];
  bool isWholesalerSearching = false;
  bool isRetailerSearching = false;
  final Set<String> _updatingLocationIds = {};

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

  void _searchDistributors(String val, List<Distributor> allDistributors) {
    searchDistributors.clear();
    final lower = val.toLowerCase();
    for (final d in allDistributors) {
      final name = (d.name ?? '').toLowerCase();
      final distName = (d.distributionName ?? '').toLowerCase();
      final town = (d.town?.name ?? '').toLowerCase();
      if (name.contains(lower) ||
          distName.contains(lower) ||
          town.contains(lower)) {
        searchDistributors.add(d);
      }
    }
    setState(() {});
  }

  void _searchWholesalers(String val, List<Wholesaler> all) {
    searchWholesalers.clear();
    final lower = val.toLowerCase();
    for (final w in all) {
      if ((w.name ?? '').toLowerCase().contains(lower) ||
          (w.address ?? '').toLowerCase().contains(lower) ||
          (w.town?.name ?? '').toLowerCase().contains(lower)) {
        searchWholesalers.add(w);
      }
    }
    setState(() {});
  }

  void _searchRetailers(String val, List<Wholesaler> all) {
    searchRetailers.clear();
    final lower = val.toLowerCase();
    for (final r in all) {
      if ((r.name ?? '').toLowerCase().contains(lower) ||
          (r.address ?? '').toLowerCase().contains(lower) ||
          (r.town?.name ?? '').toLowerCase().contains(lower)) {
        searchRetailers.add(r);
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // Default length 2; will be rebuilt in build() when role is known
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    determinePosition().then((value) {
      if (!mounted) return;
      setState(() {
        myLocation = LatLng(value.latitude, value.longitude);
        currentLocation = LatLng(value.latitude, value.longitude);
      });
      _syncDistributorsFromProvider();
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
        _syncDistributorsFromProvider();
      });
    });
  }

  /// Syncs [_fetchedDistributors] from the UserProvider (warehouseManager only).
  void _syncDistributorsFromProvider() {
    if (!mounted) return;
    final user = Provider.of<UserProvider>(context, listen: false);
    final role = user.getSalesUserDetails()?.role ?? '';
    if (role != 'warehouseManager') return;

    final list = user.getSalesUserDetails()?.distributors ?? [];
    if (list.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final retryList =
            Provider.of<UserProvider>(context, listen: false)
                .getSalesUserDetails()
                ?.distributors ??
                [];
        setState(() {
          _fetchedDistributors = retryList;
          _distributorsLoading = retryList.isEmpty;
        });
      });
    } else {
      setState(() {
        _fetchedDistributors = list;
        _distributorsLoading = false;
        _distributorsError = null;
      });
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        isDistributorSearching = false;
        isWholesalerSearching = false;
        isRetailerSearching = false;
        searchDistributors.clear();
        searchWholesalers.clear();
        searchRetailers.clear();
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Re-sync distributors on every dependency change (covers logout -> login).
    _syncDistributorsFromProvider();

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
    final role = user.getSalesUserDetails()?.role ?? '';
    final isOrderBooker = role == 'orderBooker';
    final isWarehouseManager = role == 'warehouseManager';
    final hasThreeTabs = isWarehouseManager;
    final showTabs = isOrderBooker || isWarehouseManager;

    // ── Rebuild TabController if role changed ──
    final neededLength = hasThreeTabs ? 3 : 2;
    if (_tabRole != role || _tabController.length != neededLength) {
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();
      _tabController = TabController(length: neededLength, vsync: this);
      _tabController.addListener(_onTabChanged);
      _tabRole = role;
    }

    // ── Data lists ──
    final allDistributors = _fetchedDistributors.isNotEmpty
        ? _fetchedDistributors
        : (user.getSalesUserDetails()?.distributors ?? []);
    final allWholesalers = user.getSalesUserDetails()?.wholesalers ?? [];
    final allRetailers = user.getSalesUserDetails()?.retailers ?? [];

    // ── AppBar title ──
    final appBarTitle = isOrderBooker
        ? 'Wholesalers/Retailers'
        : isWarehouseManager
        ? 'Customers'
        : 'Distributors';

    // ── Search handler — routes to correct list based on role + active tab ──
    void handleSearch(String query) {
      if (query.isEmpty) {
        isSearchingAllow = false;
        isDistributorSearching = false;
        isWholesalerSearching = false;
        isRetailerSearching = false;
        searchUser.clear();
        searchDistributors.clear();
        searchWholesalers.clear();
        searchRetailers.clear();
        setState(() {});
        return;
      }
      if (isWarehouseManager) {
        final idx = _tabController.index;
        if (idx == 0) {
          isDistributorSearching = true;
          _searchDistributors(query, allDistributors);
        } else if (idx == 1) {
          isWholesalerSearching = true;
          _searchWholesalers(query, allWholesalers);
        } else {
          isRetailerSearching = true;
          _searchRetailers(query, allRetailers);
        }
      } else if (isOrderBooker) {
        if (_tabController.index == 0) {
          isWholesalerSearching = true;
          _searchWholesalers(query, allWholesalers);
        } else {
          isRetailerSearching = true;
          _searchRetailers(query, allRetailers);
        }
      } else {
        isSearchingAllow = true;
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

    return Scaffold(
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
                log('Called');
                isSearchingAllow = false;
                isDistributorSearching = false;
                isWholesalerSearching = false;
                isRetailerSearching = false;
                searchUser.clear();
                searchDistributors.clear();
                searchWholesalers.clear();
                searchRetailers.clear();
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
          ? (_distributorsLoading && allDistributors.isEmpty)
          ? const Center(child: ProcessingWidget())
          : _distributorsError != null && allDistributors.isEmpty
          ? Center(child: Text(_distributorsError!))
          : TabBarView(
        controller: _tabController,
        children: [
          _buildDistributorView(context, allDistributors),
          _buildWholesalerListView(
            context,
            allWholesalers,
            isSearching: isWholesalerSearching,
            searchResults: searchWholesalers,
            emptyMessage: "No wholesalers assigned.",
            heading: "Wholesalers",
            isRetailer: false,
          ),
          _buildWholesalerListView(
            context,
            allRetailers,
            isSearching: isRetailerSearching,
            searchResults: searchRetailers,
            emptyMessage: "No retailers assigned.",
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
          _buildWholesalerListView(
            context,
            allWholesalers,
            isSearching: isWholesalerSearching,
            searchResults: searchWholesalers,
            emptyMessage: "No wholesalers assigned.",
            heading: "Wholesalers",
            isRetailer: false,
          ),
          _buildWholesalerListView(
            context,
            allRetailers,
            isSearching: isRetailerSearching,
            searchResults: searchRetailers,
            emptyMessage: "No retailers assigned.",
            heading: "Retailers",
            isRetailer: true,
          ),
        ],
      )
      // ── other roles (TSM): original retailer BLoC flow ──
          : _buildRetailerBlocView(context, user, search),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Wholesaler / Retailer list view (orderBooker)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWholesalerListView(
      BuildContext context,
      List<Wholesaler> all, {
        required bool isSearching,
        required List<Wholesaler> searchResults,
        required String emptyMessage,
        required String heading,
        bool isRetailer = false,
      }) {
    if (isSearching && searchResults.isEmpty) {
      return const Center(child: NoDataFoundView());
    }
    if (all.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    final displayList = isSearching ? searchResults : all;
    return ListView.builder(
      itemCount: displayList.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              "$heading (${all.length})",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: FrontendConfigs.kAuthTextColor,
              ),
            ),
          );
        }
        return _buildWholesalerCard(context, displayList[i - 1], isRetailer: isRetailer);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Distributor view — warehouseManager only
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDistributorView(
      BuildContext context,
      List<Distributor> allDistributors,
      ) {
    final displayList = (isDistributorSearching && searchDistributors.isNotEmpty)
        ? searchDistributors
        : isDistributorSearching
        ? <Distributor>[]
        : allDistributors;

    if (isDistributorSearching && searchDistributors.isEmpty) {
      return const Center(child: NoDataFoundView());
    }

    if (allDistributors.isEmpty) {
      return const Center(child: Text("No distributors assigned."));
    }

    return ListView.builder(
      itemCount: displayList.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              "Distributors (${allDistributors.length})",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: FrontendConfigs.kAuthTextColor,
              ),
            ),
          );
        }
        final d = displayList[i - 1];
        return _buildDistributorCard(context, d);
      },
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
              List<RetailerModel> _retailerList = [];
              search.saveRetailerList(state.model.data!);
              _retailerList = state.model.data!.map((e) {
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
                  customerType: e.customerType.isNotEmpty ? e.customerType : 'retailer',
                  distance: calculateDistance(
                      start: myLocation!,
                      end: LatLng(e.lat!.toDouble(), e.lng!.toDouble())),
                );
              }).toList();
              _retailerList.sort((a, b) => a.distance!.compareTo(b.distance!));

              if (searchUser.isEmpty && isSearchingAllow == true) {
                return const Center(child: NoDataFoundView());
              } else {
                final customerList =
                searchUser.isEmpty ? _retailerList : searchUser;

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
        userProvider.patchWholesalerShopLocation(id, lat, lng, address: updated.address);
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
        userProvider.patchRetailerShopLocation(id, lat, lng, address: updated.shopAddress1);
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
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      final locationProvider =
      Provider.of<LocationProvider>(context, listen: false);
      final imagePath = selectedImage?.path;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      AppLogger.debug("📍 Initial GPS location obtained");
      AppLogger.debug(
          "   Location: ${position.latitude}, ${position.longitude}");
      AppLogger.debug(
          "   Accuracy: ${position.accuracy.toStringAsFixed(2)}m");

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

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CategoryListingView(showCart: true),
        ),
      );

      if (mounted) {
        getFlushBar(context, title: "Visit Started Successfully");
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Long-press handlers — trigger the "update to current location" flow that
  // used to live on the map-icon button. Each shows the same confirmation
  // dialog, then commits via the existing per-type update methods.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _handleDistributorLongPress(
      Distributor d, String displayName) async {
    await _refreshCurrentLocation();
    if (currentLocation == null) {
      getFlushBar(context, title: "Current location not available");
      return;
    }
    await showNavigationDialog(
      context,
      message: "Update ${displayName}'s location to your current location?",
      buttonText: "Update",
      navigation: () async {
        Navigator.of(context).pop();
        try {
          final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          if (!mounted) return;
          setState(() {
            currentLocation = LatLng(pos.latitude, pos.longitude);
          });
          await _commitDistributorLocationUpdate(d, pos.latitude, pos.longitude);
        } catch (e) {
          if (mounted) {
            getFlushBar(context, title: e.toString());
          }
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
      message: "Update ${displayName}'s location to your current location?",
      buttonText: "Update",
      navigation: () async {
        Navigator.of(context).pop();
        setState(() => _updatingLocationIds.add(w.id ?? ''));
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
            await _commitWholesalerLocationUpdate(w, pos.latitude, pos.longitude);
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
      navigation: () {
        final token =
            context.read<UserProvider>().getSalesUserDetails()?.token ?? '';
        if (token.isEmpty) {
          getFlushBar(context,
              title: 'Session expired. Please log in again.');
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
                      if (!isDistributorSearching &&
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
  Widget _buildWholesalerCard(BuildContext context, Wholesaler w, {bool isRetailer = false}) {
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
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                        Text(phone,
                            style: const TextStyle(fontSize: 13)),
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
                                  fontSize: 12,
                                  color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          address,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddRecoveryView(
                              distributorId: w.id ?? '',
                              paymentType: 'market_recovery',
                              customerType: isRetailer ? 'retailer' : 'wholesaler',
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
                                    width: MediaQuery.of(context).size.width *
                                        0.6,
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
                                  child: const Icon(
                                      CupertinoIcons.cart_fill,
                                      color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddRecoveryView(
                                        distributorId: currentRetailer.id?.toString() ?? '',
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