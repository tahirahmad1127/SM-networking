import 'dart:async';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sm_networking/application/category_bloc/category_bloc.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/infrastructure/model/category.dart';
import 'package:sm_networking/infrastructure/services/category.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:sm_networking/presentation/view/categories/categories_view.dart';
import 'package:sm_networking/presentation/view/order/no_data_found_view.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

import '../../../application/location.dart';
import '../../../application/retailer_provider.dart';
import '../../../application/visit_bloc/visit_bloc.dart';
import '../../../application/visit_provider.dart';
import '../../../infrastructure/model/visit.dart';
import '../../../injection_container.dart';
import '../../elements/flush_bar.dart';
import '../../elements/my_logger.dart';

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
    // DON'T start a timer here - VisitProvider already has one!
    AppLogger.debug("📱 CategoryListingView loaded - VisitProvider timer should already be running");
  }

  @override
  void dispose() {
    AppLogger.debug("🔴 CategoryListingView disposing");
    _isDisposed = true;
    super.dispose();
  }

  /// Handle back button press
  Future<bool> _handleBackPress() async {
    AppLogger.debug("🔙 Back button pressed in CategoryListingView");
    _isDisposed = true;

    final visitProvider = Provider.of<VisitProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final retailerProvider = Provider.of<RetailerProvider>(context, listen: false);

    // Stop VisitProvider timer
    visitProvider.stopLocationMonitoring();
    AppLogger.debug("🛑 VisitProvider timer stopped on back press");

    // If already auto-logged, just clear and allow back
    if (visitProvider.isVisitAutoLogged) {
      AppLogger.debug("Visit already auto-logged, clearing and allowing back navigation");
      await visitProvider.clearVisitData();
      return true;
    }

    final startVisit = await visitProvider.getStartVisit();
    final visitLocation = visitProvider.visitLocation;

    // If no active visit, just allow back
    if (startVisit == null || visitLocation == null) {
      AppLogger.debug("No active visit to check");
      await visitProvider.clearVisitData();
      return true;
    }

    // Get FRESH current location using Geolocator
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final currentLocation = LatLng(position.latitude, position.longitude);

    AppLogger.debug("📍 Back Press - Location Check:");
    AppLogger.debug("   START: ${visitLocation.latitude}, ${visitLocation.longitude}");
    AppLogger.debug("   CURRENT: ${currentLocation.latitude}, ${currentLocation.longitude}");

    // Check if moved beyond threshold
    final hasMovedAway = visitProvider.hasMovedBeyondThreshold(
      currentLocation,
      thresholdMeters: 20,
    );

    if (hasMovedAway) {
      // User moved >20m - LOG VISIT via API
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
          getFlushBar(context, title: "Visit logged. You moved away from location.");
        }

        AppLogger.debug("✅ Visit logged via API and data cleared");
      }
    } else {
      // User still within 20m - JUST CLEAR (no API call)
      AppLogger.debug("✅ User still within 20m - just clearing visit data");
      await visitProvider.clearVisitData();
      AppLogger.debug("🧹 Visit data cleared (no API call - still nearby)");
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<UserProvider>(context);

    return WillPopScope(
      onWillPop: _handleBackPress,
      child: BlocProvider(
        create: (context) => sl<VisitBloc>(),
        child: BlocListener<VisitBloc, VisitState>(
          listener: (context, state) {
            if (state is VisitLoaded) {
              AppLogger.debug("✅ Visit Added Successfully via API");
              // After visit is logged, clear the data
              final visitProvider = Provider.of<VisitProvider>(context, listen: false);
              visitProvider.clearVisitData();
            } else if (state is VisitFailed) {
              AppLogger.debug("❌ Visit Add Failed: ${state.message}");
            }
          },
          child: Scaffold(
            appBar: customAppBar(context, text: 'Categories', showText: true),
            body: BlocProvider(
              create: (context) => sl<CategoryBloc>(),
              child: BlocBuilder<CategoryBloc, CategoryState>(
                builder: (context, state) {
                  if (state is CategoryInitial) {
                    BlocProvider.of<CategoryBloc>(context).add(GetCategoryEvent(
                        user.getSalesUserDetails()!.user!.zone.toString()));
                    return const Center(
                      child: ProcessingWidget(),
                    );
                  } else if (state is CategoryLoading) {
                    return const Center(
                      child: ProcessingWidget(),
                    );
                  } else if (state is CategoryLoaded) {
                    return ListView.builder(
                        itemCount: state.model.data!.length,
                        itemBuilder: (context, i) {
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CategoriesView(
                                        model: state.model.data![i],
                                        showCart: widget.showCart,
                                      )));
                            },
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 13.0),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 10),
                                      SizedBox(
                                        height: 40,
                                        width: 40,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(100),
                                          child: ExtendedImage.network(
                                            state.model.data![i].image.toString(),
                                            cacheHeight: 200,
                                            cacheWidth: 200,
                                            fit: BoxFit.fill,
                                            cache: true,
                                            loadStateChanged:
                                                (ExtendedImageState state) {
                                              switch (state.extendedImageLoadState) {
                                                case LoadState.loading:
                                                  return Shimmer.fromColors(
                                                    baseColor: Colors.grey.shade300,
                                                    highlightColor:
                                                    Colors.grey.shade100,
                                                    child: Image.asset(
                                                      "assets/images/karyana.png",
                                                      fit: BoxFit.fill,
                                                      color: Colors.grey,
                                                    ),
                                                  );
                                                case LoadState.failed:
                                                  return Image.asset(
                                                    "assets/images/karyana.png",
                                                    fit: BoxFit.fill,
                                                    color: Colors.grey[350],
                                                  );
                                                default:
                                                  return state.completedWidget;
                                              }
                                            },
                                            borderRadius: const BorderRadius.all(
                                                Radius.circular(30.0)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          state.model.data![i].englishName.toString(),
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
                        });
                  } else if (state is CategoryFailed) {
                    return Center(
                      child: Text(state.message.toString()),
                    );
                  } else {
                    return const Center(
                      child: Text("Something went wrong."),
                    );
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