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
import '../../../infrastructure/model/site_visit.dart';
import '../../../infrastructure/model/visit.dart';
import '../../../infrastructure/services/site_visit.dart';
import '../../elements/my_logger.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

import '../add_distributor_retailer_wholesaler/add_distributor.dart';
import '../add_distributor_retailer_wholesaler/add_retailer.dart';
import '../add_distributor_retailer_wholesaler/add_wholesaler.dart';

class GoogleMpaView extends StatefulWidget {
  const GoogleMpaView({super.key});

  @override
  State<GoogleMpaView> createState() => _GoogleMpaViewState();
}

class _GoogleMpaViewState extends State<GoogleMpaView>
    with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();
  LatLng? currentLocation;
  Set<Marker> markerSet = {};
  BitmapDescriptor? destinationIcon;

  // Tab controller — 3 tabs for warehouseManager, 2 for orderBooker
  // Length is set in initState after role is known; rebuilt if role changes.
  late TabController _tabController;
  String _tabRole = ''; // tracks which role the controller was built for

  // Selected item shown in the bottom card.
  // For TSM/warehouseManager: Distributor. For orderBooker: Wholesaler.
  Distributor? _selectedDistributor;
  Wholesaler? _selectedWholesaler;

  bool _loadingCheckIn = true;
  bool _markersInitialized = false; // flipped to true after first successful load

  /// Loads markers for whichever tab is currently active.
  /// Safe to call from didChangeDependencies and after add-screens return.
  void _loadMarkersForCurrentTab() {
    final u = Provider.of<UserProvider>(context, listen: false);
    final role = u.getSalesUserDetails()?.role ?? '';
    final isWarehouseManager = role == 'warehouseManager';
    final index = _tabController.index;

    if (isWarehouseManager) {
      if (index == 0) {
        _buildDistributorMarkers(u.getSalesUserDetails()?.distributors ?? []);
      } else if (index == 1) {
        _buildWholesalerMarkers(u.getSalesUserDetails()?.wholesalers ?? []);
      } else {
        _buildWholesalerMarkers(u.getSalesUserDetails()?.retailers ?? []);
      }
    } else {
      // orderBooker: 0 = Wholesalers, 1 = Retailers
      _buildWholesalerMarkers(index == 0
          ? (u.getSalesUserDetails()?.wholesalers ?? [])
          : (u.getSalesUserDetails()?.retailers ?? []));
    }
  }

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

  /// Build markers from the distributors list (TSM / warehouseManager).
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
          onTap: () => setState(() {
            _selectedDistributor = d;
            _selectedWholesaler = null;
          }),
        ),
      );
    }
    setState(() {});
  }

  /// Build markers from a wholesalers or retailers list (orderBooker).
  Future<void> _buildWholesalerMarkers(List<Wholesaler> list) async {
    await setSourceAndDestinationIcons();
    markerSet.clear();
    _selectedWholesaler = null;
    _selectedDistributor = null;
    for (final w in list) {
      // Prefer shopLocation (manually pinned); fall back to addressFromGoogle (set by backend)
      final lat = w.shopLocation?.lat ?? w.addressFromGoogle?.lat;
      final lng = w.shopLocation?.lng ?? w.addressFromGoogle?.lng;
      if (lat == null || lng == null) continue;
      markerSet.add(
        Marker(
          markerId: MarkerId(w.id ?? UniqueKey().toString()),
          position: LatLng(lat.toDouble(), lng.toDouble()),
          icon: destinationIcon!,
          onTap: () => setState(() {
            _selectedWholesaler = w;
            _selectedDistributor = null;
          }),
        ),
      );
    }
    setState(() {});
  }

  @override
  void initState() {
    // Role isn't available synchronously in initState for some providers,
    // so default to 2; it will be rebuilt in build() if role differs.
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Only fire on index changes, not animation mid-swipe
      if (_tabController.indexIsChanging) return;
      _loadMarkersForCurrentTab();
    });
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
  void dispose() {
    _tabController.removeListener(_loadMarkersForCurrentTab);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Stop visit location monitoring if no active visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final visitProvider = Provider.of<VisitProvider>(context, listen: false);
      if (visitProvider.startVisit == null) {
        visitProvider.stopLocationMonitoring();
        AppLogger.debug("🛑 Stopped VisitProvider timer on return to map");
      }
    });

    // Load markers as soon as UserProvider has data.
    // didChangeDependencies fires every time a Provider this widget listens to
    // changes — so this catches the splash async load completing.
    final u = Provider.of<UserProvider>(context, listen: false);
    final hasData = u.getSalesUserDetails() != null;
    if (hasData && !_markersInitialized) {
      _markersInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadMarkersForCurrentTab();
      });
    }
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
    final role = user.getSalesUserDetails()?.role ?? '';
    final isOrderBooker = role == 'orderBooker';
    final isWarehouseManager = role == 'warehouseManager';
    final hasThreeTabs = isWarehouseManager;

    // ── Rebuild TabController if role changed (e.g. logout → re-login) ──
    final neededLength = hasThreeTabs ? 3 : 2;
    if (_tabRole != role || _tabController.length != neededLength) {
      _tabController.removeListener(_loadMarkersForCurrentTab);
      _tabController.dispose();
      _tabController = TabController(length: neededLength, vsync: this);
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) return;
        _loadMarkersForCurrentTab();
      });
      _tabRole = role;
      _markersInitialized = false; // allow reload for new role
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _markersInitialized = true;
          _loadMarkersForCurrentTab();
        }
      });
    }

    if (_loadingCheckIn) {
      return const Scaffold(
        body: Center(child: ProcessingWidget()),
      );
    }

    // ── Tab definitions ──
    final showTabs = isOrderBooker || isWarehouseManager;
    final tabs = isWarehouseManager
        ? const [
      Tab(text: "Distributors"),
      Tab(text: "Wholesalers"),
      Tab(text: "Retailers"),
    ]
        : const [
      Tab(text: "Wholesalers"),
      Tab(text: "Retailers"),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isOrderBooker
              ? "Wholesalers/Retailers"
              : isWarehouseManager
              ? "Customers"
              : "Distributors",
          style: FrontendConfigs.kSubHeadingStyle,
        ),
        bottom: showTabs
            ? TabBar(
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
          onTap: (index) {
            final u = Provider.of<UserProvider>(context, listen: false);
            if (isWarehouseManager) {
              if (index == 0) {
                final distributors =
                    u.getSalesUserDetails()?.distributors ?? [];
                _buildDistributorMarkers(distributors);
              } else if (index == 1) {
                final wholesalers =
                    u.getSalesUserDetails()?.wholesalers ?? [];
                _buildWholesalerMarkers(wholesalers);
              } else {
                final retailers =
                    u.getSalesUserDetails()?.retailers ?? [];
                _buildWholesalerMarkers(retailers);
              }
            } else {
              // orderBooker: 0 = Wholesalers, 1 = Retailers
              final wholesalers =
                  u.getSalesUserDetails()?.wholesalers ?? [];
              final retailers =
                  u.getSalesUserDetails()?.retailers ?? [];
              _buildWholesalerMarkers(
                  index == 0 ? wholesalers : retailers);
            }
          },
          tabs: tabs,
        )
            : null,
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
                  // Add button — opens the correct add screen based on active tab
                  // Shown for warehouseManager and orderBooker (not plain TSM)
                  if (isWarehouseManager || isOrderBooker)
                    IconButton(
                      onPressed: isCheckedIn
                          ? () async {
                        final tabIndex = _tabController.index;

                        if (isOrderBooker) {
                          // orderBooker tabs: 0 = Wholesalers, 1 = Retailers
                          if (tabIndex == 0) {
                            // Wholesalers tab
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const AddWholesalerView()),
                            );
                            if (mounted) {
                              final wholesalers =
                                  Provider.of<UserProvider>(context,
                                      listen: false)
                                      .getSalesUserDetails()
                                      ?.wholesalers ??
                                      [];
                              _buildWholesalerMarkers(wholesalers);
                            }
                          } else {
                            // Retailers tab
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const AddRetailerView()),
                            );
                            if (mounted) {
                              final retailers =
                                  Provider.of<UserProvider>(context,
                                      listen: false)
                                      .getSalesUserDetails()
                                      ?.retailers ??
                                      [];
                              _buildWholesalerMarkers(retailers);
                            }
                          }
                        } else if (isWarehouseManager) {
                          // warehouseManager tabs: 0 = Distributors, 1 = Wholesalers, 2 = Retailers
                          if (tabIndex == 1) {
                            // Wholesalers tab
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const AddWholesalerView()),
                            );
                            if (mounted) {
                              final wholesalers =
                                  Provider.of<UserProvider>(context,
                                      listen: false)
                                      .getSalesUserDetails()
                                      ?.wholesalers ??
                                      [];
                              _buildWholesalerMarkers(wholesalers);
                            }
                          } else if (tabIndex == 2) {
                            // Retailers tab
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const AddRetailerView()),
                            );
                            if (mounted) {
                              final retailers =
                                  Provider.of<UserProvider>(context,
                                      listen: false)
                                      .getSalesUserDetails()
                                      ?.retailers ??
                                      [];
                              _buildWholesalerMarkers(retailers);
                            }
                          } else {
                            // Distributors tab (tab 0)
                            final added = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const AddDistributorView()),
                            );
                            if (added == true && mounted) {
                              final distributors =
                                  Provider.of<UserProvider>(context,
                                      listen: false)
                                      .getSalesUserDetails()
                                      ?.distributors ??
                                      [];
                              _buildDistributorMarkers(distributors);
                            }
                          }
                        } else {
                          // TSM — always distributor (no tabs)
                          final added = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                const AddDistributorView()),
                          );
                          if (added == true && mounted) {
                            final distributors =
                                Provider.of<UserProvider>(context,
                                    listen: false)
                                    .getSalesUserDetails()
                                    ?.distributors ??
                                    [];
                            _buildDistributorMarkers(distributors);
                          }
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
              if (_selectedWholesaler != null)
                Positioned.fill(
                  bottom: 10,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _buildWholesalerCard(context),
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

  // ── Mark Attendance (site-visit/add) ──────────────────────────────────────
  /// Sends a site-visit attendance record for [distributor] to the backend.
  /// Uses current UTC time as checkIn and checkOut (same moment).
  Future<void> _markAttendance(BuildContext context, Distributor distributor) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final token = userProvider.getSalesUserDetails()?.token ?? '';
    final salesPersonID = userProvider.getSalesUserDetails()?.user?.id ?? '';

    if (token.isEmpty || salesPersonID.isEmpty) {
      getFlushBar(context, title: 'Session expired. Please log in again.');
      return;
    }

    final distributorId = (distributor.id ?? distributor.salesId ?? '').trim();
    if (distributorId.isEmpty) {
      getFlushBar(context, title: 'Missing distributor ID');
      return;
    }

    final now = DateTime.now();
    final dateStr = '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';

    final request = SiteVisitRequest(
      salesPersonID: salesPersonID,
      retailerID: distributorId,
      shopName: distributor.distributionName ?? distributor.name ?? '',
      retailerEmail: distributor.email ?? '',
      retailerImage: distributor.image ?? '',
      date: dateStr,
      checkIn: now.toIso8601String(),
      checkOut: now.toIso8601String(),
      image: '',
    );

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  FrontendConfigs.kPrimaryColor,
                ),
                strokeWidth: 3,
              ),
              const SizedBox(height: 20),
              const Text(
                "Marking Your Attendance",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff121212),
                  fontFamily: "Inter",
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Please wait...",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontFamily: "Inter",
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final result = await SiteVisitService().markAttendance(
      request: request,
      token: token,
    );

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // dismiss loader

    result.fold(
          (failure) => getFlushBar(context, title: failure.error),
          (_) => getFlushBar(
        context,
        title: 'Attendance marked for ${distributor.name ?? 'distributor'}',
      ),
    );
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
          constraints: const BoxConstraints(minHeight: 150, maxHeight: 250),
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
                                paymentType: 'distributor',
                                customerType: '',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Add Payment",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    // Company Order button
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
                                  customerType: 'distributor',
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
                          "Company Order",
                          style: TextStyle(color: Colors.white, fontSize: 13),
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

  // ── Wholesaler / Retailer bottom card (orderBooker) ───────────────────────
  Widget _buildWholesalerCard(BuildContext context) {
    final w = _selectedWholesaler!;
    final displayName = w.name ?? '—';
    final phone = w.contacts ?? '';
    final address = w.address ?? '';
    final townName = w.town?.name ?? '';
    final role = Provider.of<UserProvider>(context, listen: false)
        .getSalesUserDetails()
        ?.role ??
        '';
    final isWarehouseManager = role == 'warehouseManager';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 130, maxHeight: 280),
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
                    // Avatar
                    CircleAvatar(
                      radius: 36,
                      backgroundColor:
                      FrontendConfigs.kPrimaryColor.withOpacity(0.15),
                      child: Text(
                        (w.name?.isNotEmpty == true ? w.name![0] : 'W')
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
                                      Text(phone,
                                          style: const TextStyle(fontSize: 13)),
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
                              // Location update + Dismiss buttons
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Update location to current position
                                  InkWell(
                                    onTap: () async {
                                      final whol = _selectedWholesaler!;
                                      final id = (whol.id ?? '').trim();
                                      if (id.isEmpty) {
                                        getFlushBar(context,
                                            title: 'Missing wholesaler/retailer id');
                                        return;
                                      }
                                      final userProv = context.read<UserProvider>();
                                      final token =
                                          userProv.getSalesUserDetails()?.token ?? '';
                                      if (token.isEmpty) {
                                        getFlushBar(context,
                                            title: 'Session expired. Please log in again.');
                                        return;
                                      }
                                      final locProv = context.read<LocationProvider>();
                                      try {
                                        final pos = await Geolocator.getCurrentPosition(
                                          desiredAccuracy: LocationAccuracy.high,
                                        );
                                        if (!mounted) return;
                                        final lat = pos.latitude;
                                        final lng = pos.longitude;
                                        locProv.setLatLng(LatLng(lat, lng));
                                        setState(() {
                                          currentLocation = LatLng(lat, lng);
                                        });
                                        final result = await RetailerRepositoryImp()
                                            .updateWholesalerLocation(
                                          wholesalerId: id,
                                          lat: lat,
                                          lng: lng,
                                          token: token,
                                        );
                                        if (!mounted) return;
                                        result.fold(
                                              (l) => getFlushBar(context,
                                              title: l.error.toString()),
                                              (_) {
                                            userProv.patchWholesalerShopLocation(
                                                id, lat, lng);
                                            final isWholesalerTab =
                                                _tabController.index ==
                                                    (isWarehouseManager ? 1 : 0);
                                            final updatedList = isWholesalerTab
                                                ? (userProv
                                                .getSalesUserDetails()
                                                ?.wholesalers ?? [])
                                                : (userProv
                                                .getSalesUserDetails()
                                                ?.retailers ?? []);
                                            _buildWholesalerMarkers(updatedList);
                                            Wholesaler? refreshed;
                                            for (final x in updatedList) {
                                              if (x.id == id) {
                                                refreshed = x;
                                                break;
                                              }
                                            }
                                            if (refreshed != null) {
                                              setState(() {
                                                _selectedWholesaler = refreshed;
                                              });
                                            }
                                            getFlushBar(context,
                                                title:
                                                'Location updated for ${whol.name ?? 'customer'}');
                                          },
                                        );
                                      } catch (e) {
                                        if (mounted) {
                                          getFlushBar(context, title: e.toString());
                                        }
                                      }
                                    },
                                    child: Container(
                                      height: 36,
                                      width: 36,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: FrontendConfigs.kPrimaryColor,
                                      ),
                                      child: const Icon(
                                          CupertinoIcons.location_solid,
                                          color: Colors.white,
                                          size: 18),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Dismiss card button
                                  InkWell(
                                    onTap: () =>
                                        setState(() => _selectedWholesaler = null),
                                    child: Container(
                                      height: 36,
                                      width: 36,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.grey.shade200,
                                      ),
                                      child: Icon(Icons.close,
                                          color: Colors.grey.shade700, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
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
                // Add Recovery button
                Row(
                  children: [
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
                          // warehouseManager: tab 2 = Retailers, tab 1 = Wholesalers
                          // orderBooker:      tab 1 = Retailers, tab 0 = Wholesalers
                          final isRetailerTab = _tabController.index ==
                              (isWarehouseManager ? 2 : 1);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddRecoveryView(
                                distributorId: w.id ?? '',
                                paymentType: 'market_recovery',
                                customerType:
                                isRetailerTab ? 'retailer' : 'wholesaler',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Add Recovery",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                // Start Booking button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FrontendConfigs.kPrimaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () async {
                      if (currentLocation == null) {
                        getFlushBar(context,
                            title: "Current location not available");
                        return;
                      }
                      await showVisitBottomSheet(context,
                              (selectedImage) async {
                            String? imagePath;
                            if (selectedImage != null) {
                              imagePath =
                              await _openProEditor(selectedImage.path);
                            }
                            final position =
                            await Geolocator.getCurrentPosition(
                              desiredAccuracy: LocationAccuracy.high,
                            );
                            final visitProvider =
                            Provider.of<VisitProvider>(context, listen: false);
                            await visitProvider.setStartVisit(
                              location: currentLocation!,
                              imagePath: imagePath,
                              accuracy: position.accuracy,
                              onLocationCheckCallback: () async {},
                            );

                            // Map Wholesaler → RetailerModel for downstream screens
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
                              customerType: (_tabController.index == (isWarehouseManager ? 2 : 1))
                                  ? 'retailer' : 'wholesaler',
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
                      "Start Market Booking",
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}