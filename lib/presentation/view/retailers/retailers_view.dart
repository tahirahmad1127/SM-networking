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

class _RetailersViewState extends State<RetailersView> {
  LatLng? myLocation;
  LatLng? currentLocation;

  // ── Retailer search (non-distributor roles) ──
  List<RetailerModel> searchUser = [];
  bool isSearchingAllow = false;
  bool isSearched = false;

  // ── Distributor search (warehouseManager / orderBooker) ──
  List<Distributor> searchDistributors = [];
  bool isDistributorSearching = false;

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

  @override
  void initState() {
    determinePosition().then((value) {
      myLocation = LatLng(value.latitude!, value.longitude!);
      currentLocation = LatLng(value.latitude!, value.longitude!);
      setState(() {});
    });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

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

    // FIX: both warehouseManager and orderBooker show the distributor view,
    // because the orderBooker API also returns a populated distributors list.
    final role = user.getSalesUserDetails()?.role ?? '';
    final showDistributorView =
        role == 'warehouseManager' || role == 'orderBooker';

    final allDistributors =
        user.getSalesUserDetails()?.distributors ?? [];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedSearchAppBar(
          title: 'Customers',
          onCancel: () {
            log('Called');
            isSearchingAllow = false;
            isDistributorSearching = false;
            searchUser.clear();
            searchDistributors.clear();
            setState(() {});
          },
          onSearch: (query) {
            if (query == "") {
              isSearchingAllow = false;
              isDistributorSearching = false;
              searchUser.clear();
              searchDistributors.clear();
              setState(() {});
            } else {
              if (showDistributorView) {
                isDistributorSearching = true;
                _searchDistributors(query, allDistributors);
              } else {
                isSearchingAllow = true;
                _searchData(query);
              }
            }
          },
        ),
      ),
      body: myLocation == null
          ? const Center(child: ProcessingWidget())
          : showDistributorView
      // ── warehouseManager / orderBooker: show distributors directly ──
          ? _buildDistributorView(context, allDistributors)
      // ── other roles: original retailer BLoC flow ──
          : _buildRetailerBlocView(context, user, search),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Distributor view — used by warehouseManager AND orderBooker
  // Reads distributors from UserProvider directly (no BLoC needed)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDistributorView(
      BuildContext context,
      List<Distributor> allDistributors,
      ) {
    final displayList = (isDistributorSearching && searchDistributors.isNotEmpty)
        ? searchDistributors
        : isDistributorSearching
        ? <Distributor>[] // searched but nothing found
        : allDistributors;

    if (isDistributorSearching && searchDistributors.isEmpty) {
      return const Center(child: NoDataFoundView());
    }

    if (allDistributors.isEmpty) {
      return const Center(
        child: Text("No distributors assigned."),
      );
    }

    return ListView.builder(
      // +1 for the heading row at index 0
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
      child: InkWell(
        onTap: () async {
          if (currentLocation == null) {
            getFlushBar(context, title: "Current location not available");
            return;
          }

          await showVisitBottomSheet(context, (selectedImage) async {
            final visitProvider =
            Provider.of<VisitProvider>(context, listen: false);
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
                  AppLogger.debug(
                      "📍 Fresh GPS location obtained in timer callback");
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
                    final userDetails =
                        userProvider.getSalesUserDetails()?.user;
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

            // Resolve a non-empty shipping address before saving retailer
            final resolvedAddress = _resolveDistributorAddress(d);

            // Map Distributor → RetailerModel for downstream screens
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
            );

            Provider.of<RetailerProvider>(context, listen: false)
                .saveRetailer(asRetailer);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                const CategoryListingView(showCart: true),
              ),
            );

            if (mounted) {
              getFlushBar(context, title: "Visit Started Successfully");
            }
          });
        },
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
                  radius: 30,
                  backgroundColor:
                  FrontendConfigs.kPrimaryColor.withOpacity(0.12),
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
                    // Update location
                    InkWell(
                      onTap: () async {
                        await _refreshCurrentLocation();
                        if (currentLocation == null) {
                          getFlushBar(context,
                              title: "Current location not available");
                          return;
                        }
                        await showNavigationDialog(
                          context,
                          message:
                          "Update ${displayName}'s location to your current location?",
                          buttonText: "Update",
                          navigation: () {
                            // Distributor location update — wire to your endpoint if available
                            getFlushBar(context,
                                title: "Location updated for $displayName");
                            Navigator.pop(context);
                          },
                          secondButtonText: "Cancel",
                          showSecondButton: true,
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
                        child: const Icon(CupertinoIcons.location_solid,
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
                              retailerId: d.id ?? d.salesId ?? '',
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
        onTap: () async {
          if (currentLocation == null) {
            getFlushBar(context, title: "Current location not available");
            return;
          }

          await showVisitBottomSheet(context, (selectedImage) async {
            final visitProvider =
            Provider.of<VisitProvider>(context, listen: false);
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
                  AppLogger.debug(
                      "📍 Fresh GPS location obtained in timer callback");
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
                    final userDetails =
                        userProvider.getSalesUserDetails()?.user;
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
                .saveRetailer(currentRetailer);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                const CategoryListingView(showCart: true),
              ),
            );

            if (mounted) {
              getFlushBar(context, title: "Visit Started Successfully");
            }
          });
        },
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
                              InkWell(
                                onTap: () async {
                                  await _refreshCurrentLocation();
                                  if (currentLocation == null) {
                                    getFlushBar(context,
                                        title:
                                        "Current location not available");
                                    return;
                                  }
                                  await showNavigationDialog(
                                    context,
                                    message:
                                    "Update ${currentRetailer.shopName}'s location to your current location?",
                                    buttonText: "Update",
                                    navigation: () {
                                      BlocProvider.of<RetailerBloc>(context)
                                          .add(UpdateRetailerLocationEvent(
                                        retailerId:
                                        currentRetailer.id.toString(),
                                        lat: currentLocation!.latitude,
                                        lng: currentLocation!.longitude,
                                      ));
                                      Navigator.pop(context);
                                    },
                                    secondButtonText: "Cancel",
                                    showSecondButton: true,
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
                                      CupertinoIcons.location_solid,
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
                                        retailerId:
                                        currentRetailer.id.toString(),
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