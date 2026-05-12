import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sm_networking/application/visit_provider.dart';
import 'package:sm_networking/application/location.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/application/retailer_provider.dart';
import 'package:sm_networking/infrastructure/model/visit.dart';
import 'package:sm_networking/application/visit_bloc/visit_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sm_networking/presentation/elements/my_logger.dart';

import '../../../elements/flush_bar.dart';

/// Widget to automatically check visit status when navigating away
class VisitChecker extends StatefulWidget {
  final Widget child;

  const VisitChecker({super.key, required this.child});

  @override
  State<VisitChecker> createState() => _VisitCheckerState();
}

class _VisitCheckerState extends State<VisitChecker> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _checkAndLogVisit();
    }
  }

  Future<void> _checkAndLogVisit() async {
    final visitProvider = Provider.of<VisitProvider>(context, listen: false);
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final retailerProvider = Provider.of<RetailerProvider>(context, listen: false);

    // Check if there's an active visit
    final startVisit = await visitProvider.getStartVisit();
    final visitLocation = visitProvider.visitLocation;

    if (startVisit == null || visitLocation == null) {
      AppLogger.debug("No active visit to log");
      return;
    }

    try {
      // Get FRESH GPS location with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final currentLocation = LatLng(position.latitude, position.longitude);
      final accuracy = position.accuracy;

      log("📍 VisitChecker - Fresh GPS location obtained");
      log("   Location: ${position.latitude}, ${position.longitude}");
      log("   Accuracy: ${accuracy.toStringAsFixed(2)} m");

      // Update LocationProvider with fresh location
      locationProvider.setLatLng(currentLocation);

      // Use the new checkAndAutoLogVisit method with accuracy
      await visitProvider.checkAndAutoLogVisit(
        currentLocation: currentLocation,
        currentAccuracy: position.accuracy,
        onShowNotification: (message) {
          // Show notification to user
          if (context.mounted) {
            getFlushBar(context, title: message);
          }
        },
        onAutoLogVisit: () async {
          AppLogger.debug("🚶 User moved away - logging visit automatically");

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

            // Log the visit
            if (mounted) {
              context.read<VisitBloc>().add(AddVisitEvent(visit));
            }

            // Clear visit data
            await visitProvider.clearVisitData();
            AppLogger.debug("✅ Visit logged and cleared");
          }
        },
      );
    } catch (e) {
      AppLogger.debug("❌ Error getting location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension to use in navigation
extension VisitCheckNavigation on BuildContext {
  Future<void> checkVisitBeforeNavigation() async {
    final visitProvider = Provider.of<VisitProvider>(this, listen: false);
    final locationProvider = Provider.of<LocationProvider>(this, listen: false);
    final userProvider = Provider.of<UserProvider>(this, listen: false);
    final retailerProvider = Provider.of<RetailerProvider>(this, listen: false);

    final startVisit = await visitProvider.getStartVisit();
    final visitLocation = visitProvider.visitLocation;

    if (startVisit != null && visitLocation != null) {
      try {
        // Get FRESH GPS location with high accuracy
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final currentLocation = LatLng(position.latitude, position.longitude);
        final accuracy = position.accuracy;

        AppLogger.debug("📍 Navigation Check - Fresh GPS location obtained");
        AppLogger.debug("   Location: ${position.latitude}, ${position.longitude}");
        AppLogger.debug("   Accuracy: ${accuracy.toStringAsFixed(2)} m");

        // Update LocationProvider with fresh location
        locationProvider.setLatLng(currentLocation);

        // Use the new checkAndAutoLogVisit method with accuracy
        await visitProvider.checkAndAutoLogVisit(
          currentLocation: currentLocation,
          onAutoLogVisit: () async {
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

              read<VisitBloc>().add(AddVisitEvent(visit));
              await visitProvider.clearVisitData();

              AppLogger.debug("✅ Visit auto-logged on navigation");
            }
          },
        );
      } catch (e) {
        AppLogger.debug("❌ Error getting location: $e");
      }
    }
  }
}