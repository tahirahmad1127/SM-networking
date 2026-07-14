import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sm_networking/application/brand_bloc/brand_bloc.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:provider/provider.dart';

import '../../../application/location.dart';
import '../../../application/retailer_provider.dart';
import '../../../application/visit_bloc/visit_bloc.dart';
import '../../../application/visit_provider.dart';
import '../../../infrastructure/model/visit.dart';
import '../../../injection_container.dart';
import '../../elements/flush_bar.dart';
import '../../elements/my_logger.dart';
import '../brand_category/brand_category.dart';

class CategoryListingView extends StatefulWidget {
  final bool showCart;

  const CategoryListingView({super.key, this.showCart = false});

  @override
  State<CategoryListingView> createState() => _CategoryListingViewState();
}

class _CategoryListingViewState extends State<CategoryListingView> {
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    AppLogger.debug(
        "📱 CategoryListingView loaded - VisitProvider timer should already be running");
  }

  @override
  void dispose() {
    AppLogger.debug("🔴 CategoryListingView disposing");
    _isDisposed = true;
    super.dispose();
  }

  Future<bool> _handleBackPress() async {
    AppLogger.debug("🔙 Back button pressed in CategoryListingView");
    _isDisposed = true;

    final visitProvider = Provider.of<VisitProvider>(context, listen: false);
    final locationProvider =
        Provider.of<LocationProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final retailerProvider =
        Provider.of<RetailerProvider>(context, listen: false);

    visitProvider.stopLocationMonitoring();
    AppLogger.debug("🛑 VisitProvider timer stopped on back press");

    if (visitProvider.isVisitAutoLogged) {
      AppLogger.debug(
          "Visit already auto-logged, clearing and allowing back navigation");
      await visitProvider.clearVisitData();
      return true;
    }

    final startVisit = await visitProvider.getStartVisit();
    final visitLocation = visitProvider.visitLocation;

    if (startVisit == null || visitLocation == null) {
      AppLogger.debug("No active visit to check");
      await visitProvider.clearVisitData();
      return true;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final currentLocation = LatLng(position.latitude, position.longitude);

    AppLogger.debug("📍 Back Press - Location Check:");
    AppLogger.debug(
        "   START: ${visitLocation.latitude}, ${visitLocation.longitude}");
    AppLogger.debug(
        "   CURRENT: ${currentLocation.latitude}, ${currentLocation.longitude}");

    final hasMovedAway = visitProvider.hasMovedBeyondThreshold(
      currentLocation,
      thresholdMeters: 20,
    );

    if (hasMovedAway) {
      AppLogger.debug("🚶 User moved away >20m - logging visit on back press");

      final selectedRetailer = retailerProvider.getRetailer();
      final userDetails = userProvider.getSalesUserDetails()?.user;

      if (selectedRetailer != null && userDetails != null) {
        final visit = VisitModel(
          retailerId: selectedRetailer.id.toString(),
          salesPersonId: userDetails.id.toString(),
          startTime: startVisit.toIso8601String(),
          endTime: DateTime.now().toIso8601String(),
          date: DateTime.now().toString().split(' ')[0],
          image: visitProvider.visitImage ?? "",
        );

        if (mounted) {
          context.read<VisitBloc>().add(AddVisitEvent(visit));
        }

        await visitProvider.clearVisitData();

        if (mounted) {
          getFlushBar(context,
              title: "Visit logged. You moved away from location.");
        }

        AppLogger.debug("✅ Visit logged via API and data cleared");
      }
    } else {
      AppLogger.debug("✅ User still within 20m - just clearing visit data");
      await visitProvider.clearVisitData();
      AppLogger.debug("🧹 Visit data cleared (no API call - still nearby)");
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackPress,
      child: BlocProvider(
        create: (context) => sl<VisitBloc>(),
        child: BlocListener<VisitBloc, VisitState>(
          listener: (context, state) {
            if (state is VisitLoaded) {
              AppLogger.debug("✅ Visit Added Successfully via API");
              final visitProvider =
                  Provider.of<VisitProvider>(context, listen: false);
              visitProvider.clearVisitData();
            } else if (state is VisitFailed) {
              AppLogger.debug("❌ Visit Add Failed: ${state.message}");
            }
          },
          child: Scaffold(
            appBar: customAppBar(context, text: 'Brands', showText: true),
            body: BlocProvider(
              create: (context) =>
                  sl<BrandBloc>()..add(const GetAllBrandsEvent()),
              child: BlocBuilder<BrandBloc, BrandState>(
                builder: (context, state) {
                  if (state is BrandInitial || state is BrandLoading) {
                    return const Center(child: ProcessingWidget());
                  } else if (state is AllBrandsLoaded) {
                    final brands = state.model.data ?? [];

                    if (brands.isEmpty) {
                      return const Center(child: Text("No brands found."));
                    }

                    return ListView.builder(
                      itemCount: brands.length,
                      itemBuilder: (context, i) {
                        final brand = brands[i];
                        return InkWell(
                          onTap: () async {
                            // Pause location monitoring while on brand page —
                            // prevents VisitProvider.notifyListeners() from
                            // rebuilding this screen and re-triggering initState
                            // on BrandCategoriesBody.
                            final visitProvider = Provider.of<VisitProvider>(
                                context,
                                listen: false);
                            visitProvider.stopLocationMonitoring();

                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BrandCategoriesView(
                                  brand: brand,
                                  showCart: widget.showCart,
                                ),
                              ),
                            );

                            // Resume monitoring when user returns
                            if (mounted) {
                              visitProvider.resumeLocationMonitoring();
                            }
                          },
                          child: Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13.0),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 10),
                                    // No image field in this API response —
                                    // showing a placeholder icon instead
                                    Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                      child: Icon(
                                        Icons.storefront_outlined,
                                        color: Colors.grey.shade500,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        brand.englishName ?? "Unknown Brand",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 0),
                            ],
                          ),
                        );
                      },
                    );
                  } else if (state is BrandFailed) {
                    return Center(child: Text(state.message));
                  } else {
                    return const Center(child: Text("Something went wrong."));
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
