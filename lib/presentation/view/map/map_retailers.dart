import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/application/visit_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/user.dart';
import 'package:sm_networking/infrastructure/services/retailer.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:sm_networking/presentation/view/add_recovery/add_recovery.dart';
import 'package:sm_networking/presentation/view/category_listing/category_listing_view.dart';
import 'package:sm_networking/presentation/view/map/widget/visit_bottomsheet_widget.dart';
import 'package:sm_networking/presentation/view/retailers/retailers_view.dart';
import 'package:provider/provider.dart';

import '../../../application/checkIn_provider.dart';
import '../../../application/locaition_helper.dart';
import '../../../application/location.dart';
import '../../../application/retailer_provider.dart';
import '../../../application/visit_bloc/visit_bloc.dart';
import '../../../infrastructure/model/retailer.dart';
import '../../../infrastructure/model/visit.dart';
import '../../elements/my_logger.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../add_distributor/add_distributor.dart';

class GoogleMpaView extends StatefulWidget {
  const GoogleMpaView({super.key});

  @override
  State<GoogleMpaView> createState() => _GoogleMpaViewState();
}

class _GoogleMpaViewState extends State<GoogleMpaView> {
  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();
  LatLng? currentLocation;
  Set<Marker> markerSet = {};
  BitmapDescriptor? destinationIcon;

  // Selected distributor shown in the bottom card
  Distributor? _selectedDistributor;

  bool _loadingCheckIn = true;

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future setSourceAndDestinationIcons() async {
    final Uint8List icon =
    await getBytesFromAsset('assets/images/marker.png', 70);
    destinationIcon = await BitmapDescriptor.fromBytes(icon);
    return destinationIcon;
  }

  /// Build markers from the distributors list in UserProvider.
  /// Skips any distributor whose shopLocation lat or lng is null.
  Future<void> _buildDistributorMarkers(List<Distributor> distributors) async {
    await setSourceAndDestinationIcons();
    markerSet.clear();

    for (final d in distributors) {
      final lat = d.shopLocation?.lat;
      final lng = d.shopLocation?.lng;
      if (lat == null || lng == null) continue;

      markerSet.add(
        Marker(
          markerId: MarkerId(d.id ?? d.salesId ?? UniqueKey().toString()),
          position: LatLng(lat.toDouble(), lng.toDouble()),
          icon: destinationIcon!,
          onTap: () {
            setState(() {
              _selectedDistributor = d;
            });
          },
        ),
      );
    }
    setState(() {});
  }

  @override
  void initState() {
    _loadCheckInStatus();

    final location = Provider.of<LocationProvider>(context, listen: false);
    log(location.getLatLng().toString() + " Location Provider");

    if (location.getLatLng() == null) {
      log("Fetching location");
      determinePosition().then((value) {
        setState(() {
          currentLocation = LatLng(value.latitude, value.longitude);
          location.setLatLng(currentLocation!);
        });
      }).catchError((e) {
        log(e.toString());
      });
    } else {
      currentLocation = location.getLatLng();
      setState(() {});
    }

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

  Future<void> _loadCheckInStatus() async {
    final checkInProvider =
    Provider.of<CheckInProvider>(context, listen: false);
    await checkInProvider.loadStatus();
    if (mounted) {
      setState(() {
        _loadingCheckIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final distributors = user.getSalesUserDetails()?.distributors ?? [];

    final role = user.getSalesUserDetails()?.role ?? '';
    final showDistributorMarkers =
        role == 'warehouseManager' || role == 'orderBooker';

    if (distributors.isNotEmpty &&
        markerSet.isEmpty &&
        destinationIcon == null &&
        showDistributorMarkers) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _buildDistributorMarkers(distributors);
      });
    }

    if (_loadingCheckIn) {
      return const Scaffold(
        body: Center(child: ProcessingWidget()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Distributors",
          style: FrontendConfigs.kSubHeadingStyle,
        ),
        actions: [
          Consumer<CheckInProvider>(
            builder: (context, checkInProvider, _) {
              final isCheckedIn = checkInProvider.isCheckedIn;
              return Row(
                children: [
                  TextButton(
                    onPressed: isCheckedIn
                        ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RetailersView(),
                        ),
                      );
                    }
                        : null,
                    child: Text(
                      "View All",
                      style: TextStyle(
                        color: isCheckedIn ? Colors.black : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: isCheckedIn
                        ? () async {
                      final added = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddDistributorView()),
                      );
                      if (added == true && mounted) {
                        final distributors =
                            Provider.of<UserProvider>(context, listen: false)
                                .getSalesUserDetails()?.distributors ?? [];
                        _buildDistributorMarkers(distributors);
                      }
                    }
                        : null,
                    icon: Icon(
                      Icons.add,
                      color: isCheckedIn ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: currentLocation == null
          ? const Center(child: ProcessingWidget())
          : Consumer<CheckInProvider>(
        builder: (context, checkInProvider, _) {
          final isCheckedIn = checkInProvider.isCheckedIn;

          if (!isCheckedIn) {
            return const Center(
              child: Text(
                "Please Check In First To Use Retailer",
                textAlign: TextAlign.center,
              ),
            );
          }

          return Stack(
            children: [
              GoogleMap(
                mapType: MapType.normal,
                markers: markerSet,
                myLocationEnabled: true,
                zoomControlsEnabled: false,
                initialCameraPosition: CameraPosition(
                  target: currentLocation!,
                  zoom: 16,
                  tilt: 85,
                  bearing: 20,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
              ),
              if (_selectedDistributor != null)
                Positioned.fill(
                  bottom: 10,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildDistributorCard(context),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Image editing via ProImageEditor ─────────────────────────────────────
  /// Opens ProImageEditor on [bytes] and returns the edited file path,
  /// or the original path if the user cancels.
  Future<String?> _openProEditor(String originalPath) async {
    final bytes = await File(originalPath).readAsBytes();
    Uint8List? result;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProImageEditor.memory(
          bytes,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List edited) async {
              result = edited;
              Navigator.pop(context);
            },
          ),
          configs: const ProImageEditorConfigs(),
        ),
      ),
    );

    if (result != null) {
      final path =
          '${Directory.systemTemp.path}/visit_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(path).writeAsBytes(result!);
      return path;
    }
    // User cancelled editor — return original unchanged
    return originalPath;
  }

  Widget _buildDistributorCard(BuildContext context) {
    final d = _selectedDistributor!;
    final displayName = (d.distributionName?.isNotEmpty == true)
        ? d.distributionName!
        : (d.name ?? '—');
    final phone = d.phone ?? '';
    final address = d.address ?? '';
    final townName = d.town?.name ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 150, maxHeight: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar circle
                    CircleAvatar(
                      radius: 36,
                      backgroundColor:
                      FrontendConfigs.kPrimaryColor.withOpacity(0.15),
                      child: Text(
                        (d.name?.isNotEmpty == true ? d.name![0] : 'D')
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: FrontendConfigs.kPrimaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (phone.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        phone,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                    if (townName.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.map_pin,
                                              size: 12,
                                              color: Colors.grey.shade500),
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
                                  ],
                                ),
                              ),

                              /// Location update button — uses MongoDB _id, correct endpoint
                              InkWell(
                                onTap: () async {
                                  final dist = _selectedDistributor!;
                                  // Use MongoDB ObjectId (_id), NOT salesId
                                  final id = (dist.id ?? dist.salesId ?? '').trim();
                                  if (id.isEmpty) {
                                    getFlushBar(context,
                                        title: 'Missing distributor id');
                                    return;
                                  }
                                  final userProv = context.read<UserProvider>();
                                  final token =
                                      userProv.getSalesUserDetails()?.token ?? '';
                                  if (token.isEmpty) {
                                    getFlushBar(context,
                                        title:
                                        'Session expired. Please log in again.');
                                    return;
                                  }
                                  final locProv =
                                  context.read<LocationProvider>();
                                  try {
                                    final pos =
                                    await Geolocator.getCurrentPosition(
                                      desiredAccuracy: LocationAccuracy.high,
                                    );
                                    if (!mounted) return;
                                    final lat = pos.latitude;
                                    final lng = pos.longitude;
                                    locProv.setLatLng(LatLng(lat, lng));
                                    setState(() {
                                      currentLocation = LatLng(lat, lng);
                                    });

                                    // ✅ Correct endpoint: sale-user/location/{id}
                                    final result = await RetailerRepositoryImp()
                                        .updateDistributorLocation(
                                      distributorId: id,
                                      lat: lat,
                                      lng: lng,
                                      token: token,
                                    );
                                    if (!mounted) return;
                                    result.fold(
                                          (l) => getFlushBar(context,
                                          title: l.error.toString()),
                                          (_) {
                                        // Patch in-memory + refresh marker position
                                        userProv.patchDistributorShopLocation(
                                            id, lat, lng);

                                        final updatedList = userProv
                                            .getSalesUserDetails()
                                            ?.distributors ??
                                            [];

                                        // Find the refreshed distributor object
                                        Distributor? refreshed;
                                        for (final x in updatedList) {
                                          if (x.id == id || x.salesId == id) {
                                            refreshed = x;
                                            break;
                                          }
                                        }

                                        // Rebuild markers so the pin moves on the map
                                        _buildDistributorMarkers(updatedList);

                                        // Update the bottom card with new location data
                                        if (refreshed != null) {
                                          setState(() {
                                            _selectedDistributor = refreshed;
                                          });
                                        }

                                        getFlushBar(context,
                                            title:
                                            'Location updated for ${dist.name ?? 'distributor'}');
                                      },
                                    );
                                  } catch (e) {
                                    if (mounted) {
                                      getFlushBar(context, title: e.toString());
                                    }
                                  }
                                },
                                child: Container(
                                  height: 40,
                                  width: 40,
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
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (address.isNotEmpty)
                            Text(
                              address,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Add Recovery button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FrontendConfigs.kPrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddRecoveryView(
                                distributorId: d.id ?? d.salesId ?? '',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Add Recovery",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    // Start Order button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FrontendConfigs.kPrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () async {
                          if (currentLocation == null) {
                            getFlushBar(context,
                                title: "Current location not available");
                            return;
                          }

                          await showVisitBottomSheet(context,
                                  (selectedImage) async {
                                final visitProvider = Provider.of<VisitProvider>(
                                    context,
                                    listen: false);
                                final locationProvider =
                                Provider.of<LocationProvider>(context,
                                    listen: false);
                                // Open editor if an image was picked
                                String? imagePath;
                                if (selectedImage != null) {
                                  imagePath = await _openProEditor(selectedImage.path);
                                }

                                final position =
                                await Geolocator.getCurrentPosition(
                                  desiredAccuracy: LocationAccuracy.high,
                                );

                                AppLogger.debug("📍 Initial GPS location obtained");

                                await visitProvider.setStartVisit(
                                  location: currentLocation!,
                                  imagePath: imagePath,
                                  accuracy: position.accuracy,
                                  onLocationCheckCallback: () async {
                                    if (visitProvider.startVisit == null ||
                                        visitProvider.visitLocation == null) {
                                      AppLogger.debug(
                                          "⚠️ Visit data cleared - skipping callback");
                                      return;
                                    }

                                    Position freshPosition;
                                    try {
                                      freshPosition =
                                      await Geolocator.getCurrentPosition(
                                        desiredAccuracy: LocationAccuracy.high,
                                        timeLimit: const Duration(seconds: 5),
                                      );
                                    } catch (e) {
                                      AppLogger.debug(
                                          "❌ Failed to get fresh GPS location: $e");
                                      return;
                                    }

                                    final currentLoc = LatLng(
                                        freshPosition.latitude,
                                        freshPosition.longitude);
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
                                          AppLogger.debug(
                                              "⚠️ Visit cleared before auto-log");
                                          return;
                                        }

                                        final retailerProvider =
                                        Provider.of<RetailerProvider>(context,
                                            listen: false);
                                        final userProvider =
                                        Provider.of<UserProvider>(context,
                                            listen: false);
                                        final selectedRetailer =
                                        retailerProvider.getRetailer();
                                        final userDetails =
                                            userProvider.getSalesUserDetails()?.user;
                                        final startVisit =
                                        await visitProvider.getStartVisit();

                                        if (selectedRetailer != null &&
                                            userDetails != null &&
                                            startVisit != null) {
                                          final visit = VisitModel(
                                            retailerId:
                                            selectedRetailer.id.toString(),
                                            salesPersonId:
                                            userDetails.id.toString(),
                                            startTime:
                                            startVisit.toIso8601String(),
                                            endTime:
                                            DateTime.now().toIso8601String(),
                                            date: DateTime.now()
                                                .toString()
                                                .split(' ')[0],
                                            image: visitProvider.visitImage ?? "",
                                          );

                                          if (context.mounted) {
                                            context
                                                .read<VisitBloc>()
                                                .add(AddVisitEvent(visit));
                                            await visitProvider.clearVisitData();
                                            AppLogger.debug(
                                                "✅ Visit auto-logged via background monitoring");
                                          }
                                        }
                                      },
                                    );
                                  },
                                );

                                // Map Distributor → RetailerModel for downstream screens
                                final asRetailer = RetailerModel(
                                  id: d.id ?? d.salesId,
                                  docId: d.id ?? d.salesId,
                                  name: d.name,
                                  shopName: d.distributionName ?? d.name,
                                  shopAddress1: d.address,
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
                                  getFlushBar(context,
                                      title: "Visit Started Successfully");
                                }
                              });
                        },
                        child: const Text(
                          "Start Order",
                          style: TextStyle(color: Colors.white),
                        ),
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
}