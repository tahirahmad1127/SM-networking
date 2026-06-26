// lib/presentation/view/attendance/layout/warehouse_attendance_body.dart

import 'dart:convert';
import 'dart:developer';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:place_picker/entities/location_result.dart';
import 'package:place_picker/widgets/place_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../application/attendance_bloc/attendance_bloc.dart';
import '../../../../application/checkIn_provider.dart';
import '../../../../application/tracking_bloc/tracking_bloc.dart';
import '../../../../application/user_provider.dart';
import '../../../../configurations/frontend_configs.dart';
import '../../../../infrastructure/model/attendance.dart';
import '../../../../infrastructure/model/user.dart';
import '../../../../infrastructure/services/background_location.dart';
import '../../../../infrastructure/services/location.dart';
import '../../../../infrastructure/services/retailer.dart';
import '../../../elements/custom_text.dart';
import '../../../elements/flush_bar.dart';
import 'widget/attendance_sheets.dart';

// ── Per-distributor state persisted to SharedPreferences ─────────────────────
// Key pattern: wm_dist_{distributorId}  →  JSON { attendanceId, checkInTime, checkOutTime }

const String _kPrefix = 'wm_dist_';

class _DistState {
  final String attendanceId;
  final String checkInTime;   // ISO string
  final String? checkOutTime; // ISO string or null

  const _DistState({
    required this.attendanceId,
    required this.checkInTime,
    this.checkOutTime,
  });

  bool get isCheckedIn => checkOutTime == null || checkOutTime!.isEmpty;
  bool get isCheckedOut => !isCheckedIn;

  String get formattedCheckIn => _fmt(checkInTime);
  String get formattedCheckOut =>
      (checkOutTime == null || checkOutTime!.isEmpty) ? '--:--' : _fmt(checkOutTime!);

  String get totalHours {
    if (checkOutTime == null || checkOutTime!.isEmpty) {
      // Live duration while checked in
      final start = DateTime.tryParse(checkInTime);
      if (start == null) return '--:--';
      final diff = DateTime.now().difference(start);
      return _dur(diff);
    }
    final start = DateTime.tryParse(checkInTime);
    final end = DateTime.tryParse(checkOutTime!);
    if (start == null || end == null) return '--:--';
    return _dur(end.difference(start));
  }

  static String _fmt(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '--:--';
    return DateFormat('hh:mm a').format(dt);
  }

  static String _dur(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Map<String, dynamic> toJson() => {
    'attendanceId': attendanceId,
    'checkInTime': checkInTime,
    'checkOutTime': checkOutTime,
  };

  factory _DistState.fromJson(Map<String, dynamic> j) => _DistState(
    attendanceId: j['attendanceId'] ?? '',
    checkInTime: j['checkInTime'] ?? '',
    checkOutTime: j['checkOutTime'],
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class WarehouseAttendanceBody extends StatefulWidget {
  const WarehouseAttendanceBody({super.key});

  @override
  State<WarehouseAttendanceBody> createState() =>
      _WarehouseAttendanceBodyState();
}

class _WarehouseAttendanceBodyState extends State<WarehouseAttendanceBody> {
  LatLng? _currentLocation;

  // distId → state
  final Map<String, _DistState> _states = {};

  // distId currently being loaded (button spinner)
  final Set<String> _loading = {};

  // Which distId is pending after bloc fires (set before dispatching CheckInEvent)
  String? _pendingDistId;

  // Live ticker so "Total Hrs" updates while checked in
  late final Stream<void> _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Stream.periodic(const Duration(seconds: 30));
    _restoreAll();
    _fetchLocation();
  }

  // ── Persistence ─────────────────────────────────────────────────────────────

  String _key(String distId) => '$_kPrefix$distId';

  Future<void> _restoreAll() async {
    final prefs = await SharedPreferences.getInstance();
    final user = Provider.of<UserProvider>(context, listen: false);
    final distributors = user.getSalesUserDetails()?.distributors ?? [];
    final map = <String, _DistState>{};
    for (final d in distributors) {
      final id = (d.id ?? d.salesId ?? '').trim();
      if (id.isEmpty) continue;
      final raw = prefs.getString(_key(id));
      if (raw != null) {
        try {
          final decoded =
          Map<String, dynamic>.from(jsonDecode(raw) as Map);
          map[id] = _DistState.fromJson(decoded);
        } catch (_) {}
      }
    }
    if (mounted) setState(() => _states.addAll(map));
  }

  Future<void> _persist(String distId, _DistState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(distId), jsonEncode(state.toJson()));
    if (mounted) setState(() => _states[distId] = state);
  }

  Future<void> _clearForDist(String distId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(distId));
    if (mounted) setState(() => _states.remove(distId));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────



  bool get _anyCheckedIn =>
      _states.values.any((s) => s.isCheckedIn);

  String? get _activeDistId =>
      _states.entries.firstWhere(
            (e) => e.value.isCheckedIn,
        orElse: () => const MapEntry('', _DistState(
            attendanceId: '', checkInTime: '')),
      ).key.isEmpty
          ? null
          : _states.entries
          .firstWhere((e) => e.value.isCheckedIn)
          .key;

  // ── Location ──────────────────────────────────────────────────────────────────

  Future<void> _fetchLocation() async {
    final loc = await LocationService.getCurrentLatLng(context);
    if (loc != null && mounted) setState(() => _currentLocation = loc);
  }

  double _distance(LatLng a, LatLng b) {
    const R = 6371000.0;
    const toRad = math.pi / 180;
    final dLat = (b.latitude - a.latitude) * toRad;
    final dLng = (b.longitude - a.longitude) * toRad;
    final lat1 = a.latitude * toRad;
    final lat2 = b.latitude * toRad;
    final sin1 = math.sin(dLat / 2);
    final sin2 = math.sin(dLng / 2);
    final x = sin1 * sin1 + math.cos(lat1) * math.cos(lat2) * sin2 * sin2;
    return R * 2 * math.asin(math.sqrt(x.clamp(0.0, 1.0)));
  }

  // ── Check-In ──────────────────────────────────────────────────────────────────

  Future<void> _onUpdateLocation(BuildContext context, Distributor d) async {
    final distId = (d.id ?? d.salesId ?? '').trim();
    if (distId.isEmpty) return;
    final userProv = Provider.of<UserProvider>(context, listen: false);
    final token = userProv.getSalesUserDetails()?.token ?? '';
    if (token.isEmpty) {
      getFlushBar(context, title: 'Session expired. Please log in again.');
      return;
    }

    final existingLat = d.shopLocation?.lat;
    final existingLng = d.shopLocation?.lng;
    final LatLng? previousLocation =
    (existingLat != null && existingLng != null)
        ? LatLng(existingLat, existingLng)
        : null;

    final LatLng? picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => _UpdateDistributorLocationScreen(
          title: d.distributionName ?? d.name ?? 'Distributor',
          previousLocation: previousLocation,
        ),
      ),
    );

    if (picked == null || !mounted) return;

    try {
      final res = await RetailerRepositoryImp().updateDistributorLocation(
        distributorId: distId, lat: picked.latitude, lng: picked.longitude, token: token,
      );
      if (!mounted) return;
      res.fold(
            (l) => getFlushBar(context, title: l.error.toString()),
            (_) {
          userProv.patchDistributorShopLocation(distId, picked.latitude, picked.longitude);
          if (mounted) {
            getFlushBar(context, title: 'Location updated for ${d.distributionName ?? d.name ?? "distributor"}');
            setState(() {});
          }
        },
      );
    } catch (e) {
      if (mounted) getFlushBar(context, title: e.toString());
    }
  }

  Future<void> _onCheckIn(BuildContext ctx, Distributor d) async {
    final distId = (d.id ?? d.salesId ?? '').trim();
    if (distId.isEmpty) return;

    setState(() => _loading.add(distId));

    await _fetchLocation();

    if (_currentLocation == null) {
      if (mounted) {
        getFlushBar(ctx,
            title:
            'Cannot get your location. Please enable GPS and try again.');
      }
      setState(() => _loading.remove(distId));
      return;
    }

    final lat = d.shopLocation?.lat;
    final lng = d.shopLocation?.lng;

    if (lat == null || lng == null) {
      if (mounted) {
        getFlushBar(ctx,
            title:
            'Distributor location not set. Ask admin to pin the shop location first.');
      }
      setState(() => _loading.remove(distId));
      return;
    }

    final dist =
    _distance(_currentLocation!, LatLng(lat.toDouble(), lng.toDouble()));
    log('📍 Distance from ${d.name}: ${dist.toStringAsFixed(1)}m');

    if (dist > 20) {
      if (mounted) {
        getFlushBar(ctx,
            title:
            'You must be within 20m of ${d.distributionName ?? d.name ?? "the distributor"}. '
                'You are ${dist.toStringAsFixed(0)}m away.');
      }
      setState(() => _loading.remove(distId));
      return;
    }

    setState(() => _loading.remove(distId));
    if (!mounted) return;

    _pendingDistId = distId;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SlideToCheckInSheet(
        onComplete: () async {
          Navigator.pop(ctx);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final user =
            Provider.of<UserProvider>(ctx, listen: false);
            final userId =
                user.getSalesUserDetails()?.user?.id ?? '';
            final body = AttendanceModel(
              salesPersonId: userId,
              date:
              DateFormat('yyyy-MM-dd').format(DateTime.now()),
              lat: _currentLocation?.latitude,
              lng: _currentLocation?.longitude,
              checkInTime: DateTime.now().toIso8601String(),
              userType: 'WarehouseManager',
              distributorId: distId,
            ).toJson();
            ctx.read<AttendanceBloc>().add(CheckInEvent(body));
          });
        },
      ),
    );
  }

  // ── Check-Out ─────────────────────────────────────────────────────────────────

  Future<void> _onCheckOut(BuildContext ctx, Distributor d) async {
    final distId = (d.id ?? d.salesId ?? '').trim();
    final state = _states[distId];
    if (state == null || state.attendanceId.isEmpty) return;

    _pendingDistId = distId;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SlideToCheckOutSheet(
        onComplete: () {
          Navigator.pop(ctx);
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            final now = DateTime.now().toIso8601String();
            ctx.read<AttendanceBloc>().add(CheckOutEvent(
              state.attendanceId,
              AttendanceModel(checkOutTime: now).toJson(),
            ));
          });
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final distributors =
        user.getSalesUserDetails()?.distributors ?? [];

    return BlocListener<AttendanceBloc, AttendanceState>(
      listener: (ctx, state) async {
        final distId = _pendingDistId ?? '';

        if (state is AttendanceLoaded && state.isCheckIn) {
          if (distId.isNotEmpty) {
            await _persist(
              distId,
              _DistState(
                attendanceId: state.model.id ?? '',
                checkInTime: state.model.checkInTime ??
                    DateTime.now().toIso8601String(),
              ),
            );
            // Start tracking
            final userId =
                user.getSalesUserDetails()?.user?.id ?? '';
            await BackgroundLocationService.startTracking(userId);
            await Provider.of<CheckInProvider>(ctx, listen: false)
                .checkIn();
          }
          _pendingDistId = null;
          if (mounted) {
            getFlushBar(ctx, title: 'Checked in successfully!');
          }
        } else if (state is AttendanceLoaded && !state.isCheckIn) {
          if (distId.isNotEmpty) {
            final existing = _states[distId];
            if (existing != null) {
              await _persist(
                distId,
                _DistState(
                  attendanceId: existing.attendanceId,
                  checkInTime: existing.checkInTime,
                  checkOutTime: state.model.checkOutTime ??
                      DateTime.now().toIso8601String(),
                ),
              );
            }
            await BackgroundLocationService.stopTracking();
            await Provider.of<CheckInProvider>(ctx, listen: false)
                .checkOut();
          }
          _pendingDistId = null;
          if (mounted) {
            getFlushBar(ctx, title: 'Checked out successfully!');
          }
        } else if (state is AttendanceFailed) {
          _pendingDistId = null;
          if (mounted) {
            getFlushBar(ctx, title: 'Error: ${state.message}');
          }
        }
      },
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: 'Welcome Back!',
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: MediaQuery.of(context).size.width *
                            0.62,
                        child: CustomText(
                          text: user
                              .getSalesUserDetails()
                              ?.user
                              ?.name ??
                              'User',
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          overflow: TextOverflow.ellipsis,
                          color: const Color(0xFF2D3142),
                        ),
                      ),
                      const SizedBox(height: 2),
                      CustomText(
                        text: DateFormat.yMMMMEEEEd()
                            .format(DateTime.now()),
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.grey.shade300,
                    foregroundImage: (user
                        .getSalesUserDetails()
                        ?.user
                        ?.image ??
                        '')
                        .isNotEmpty
                        ? NetworkImage(user
                        .getSalesUserDetails()!
                        .user!
                        .image!)
                        : null,
                    child: (user
                        .getSalesUserDetails()
                        ?.user
                        ?.image ??
                        '')
                        .isNotEmpty
                        ? null
                        : const Icon(Icons.person,
                        size: 30, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: CustomText(
                text: 'Your Distributors',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 8),

            // ── List ─────────────────────────────────────────────────
            Expanded(
              child: distributors.isEmpty
                  ? const Center(
                  child: Text('No distributors assigned.'))
                  : StreamBuilder<void>(
                stream: _ticker,
                builder: (_, __) => ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  itemCount: distributors.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final d = distributors[i];
                    final dId =
                    (d.id ?? d.salesId ?? '').trim();
                    final ds = _states[dId];
                    final isActive =
                        ds != null && ds.isCheckedIn;
                    final isDone =
                        ds != null && ds.isCheckedOut;
                    final isDisabled = _anyCheckedIn &&
                        !isActive;
                    final isLoading =
                    _loading.contains(dId);

                    return GestureDetector(
                      onLongPress: () => _onUpdateLocation(ctx, d),
                      child: _DistributorCard(
                        distributor: d,
                        distState: ds,
                        isActive: isActive,
                        isDone: isDone,
                        isDisabled: isDisabled,
                        isLoading: isLoading,
                        onCheckIn: () => _onCheckIn(ctx, d),
                        onCheckOut: () => _onCheckOut(ctx, d),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Distributor Card ───────────────────────────────────────────────────────────

class _DistributorCard extends StatelessWidget {
  final Distributor distributor;
  final _DistState? distState;
  final bool isActive;   // currently checked in
  final bool isDone;     // checked out today
  final bool isDisabled; // another dist is active
  final bool isLoading;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  const _DistributorCard({
    required this.distributor,
    required this.distState,
    required this.isActive,
    required this.isDone,
    required this.isDisabled,
    required this.isLoading,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  String get _displayName =>
      (distributor.distributionName?.isNotEmpty == true)
          ? distributor.distributionName!
          : (distributor.name ?? 'Unknown');

  bool get _hasLocation =>
      distributor.shopLocation?.lat != null &&
          distributor.shopLocation?.lng != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? FrontendConfigs.kPrimaryColor.withOpacity(0.35)
              : Colors.grey.shade200,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: avatar / name / button ───────────────────
            Row(
              children: [
                // Avatar
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: FrontendConfigs.kPrimaryColor
                        .withOpacity(isActive ? 0.18 : 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.store_outlined,
                    color: FrontendConfigs.kPrimaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Name + address + location warning
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: Color(0xFF2D3142),
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (distributor.address?.isNotEmpty == true)
                        Text(
                          distributor.address!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (!_hasLocation)
                        Row(
                          children: [
                            Icon(Icons.location_off_outlined,
                                size: 12,
                                color: Colors.orange.shade500),
                            const SizedBox(width: 3),
                            Text(
                              'Location not set',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Button
                if (isLoading)
                  SizedBox(
                    width: 90,
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: FrontendConfigs.kPrimaryColor,
                        ),
                      ),
                    ),
                  )
                else if (isDone)
                // Already checked out today
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.grey.shade300, width: 1),
                    ),
                    child: Text(
                      'Checked Out',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: isDisabled
                          ? null
                          : (isActive ? onCheckOut : onCheckIn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive
                            ? Colors.orange.shade600
                            : FrontendConfigs.kPrimaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor:
                        Colors.grey.shade200,
                        disabledForegroundColor:
                        Colors.grey.shade400,
                      ),
                      child: Text(
                        isActive ? 'Check Out' : 'Check In',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Stats row (only if visited today) ─────────────────
            if (distState != null) ...[
              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade100, height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
                children: [
                  _statCell(
                    icon: Icons.login_rounded,
                    color: FrontendConfigs.kPrimaryColor,
                    value: distState!.formattedCheckIn,
                    label: 'Check In',
                  ),
                  Container(
                      width: 1,
                      height: 36,
                      color: Colors.grey.shade200),
                  _statCell(
                    icon: Icons.logout_rounded,
                    color: Colors.orange,
                    value: distState!.formattedCheckOut,
                    label: 'Check Out',
                  ),
                  Container(
                      width: 1,
                      height: 36,
                      color: Colors.grey.shade200),
                  _statCell(
                    icon: Icons.access_time_rounded,
                    color: Colors.blue,
                    value: distState!.totalHours,
                    label: 'Total Hrs',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCell({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3142),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
// ── Update Distributor Location Screen ───────────────────────────────────────
// Shown on long-press of a distributor card. Displays the previously saved
// shop location (if any) on a map with a marker, lets the user open Google
// Maps' place picker to choose a different location (search, tap, or drag —
// not limited to current GPS position), offers a "Directions" FAB to get
// turn-by-turn directions to whichever point is currently selected, and a
// Save button to confirm and return the chosen LatLng to the caller.
class _UpdateDistributorLocationScreen extends StatefulWidget {
  final String title;
  final LatLng? previousLocation;

  const _UpdateDistributorLocationScreen({
    required this.title,
    this.previousLocation,
  });

  @override
  State<_UpdateDistributorLocationScreen> createState() =>
      _UpdateDistributorLocationScreenState();
}

class _UpdateDistributorLocationScreenState
    extends State<_UpdateDistributorLocationScreen> {
  static const String _apiKey = "AIzaSyAuJYLmzmglhCpBYTn0BjbJhjWYg0fPEEA";

  LatLng? _selected;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _selected = widget.previousLocation;
  }

  Set<Marker> get _markers => _selected == null
      ? {}
      : {
    Marker(
      markerId: const MarkerId('shop_location'),
      position: _selected!,
    ),
  };

  Future<void> _openPicker() async {
    final LocationResult result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlacePicker(
          _apiKey,
          displayLocation: _selected,
        ),
      ),
    );
    if (result.latLng == null) return;
    setState(() => _selected = result.latLng);
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _selected!, zoom: 16),
      ),
    );
  }

  Future<void> _openDirections() async {
    final target = _selected;
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a location first.')),
      );
      return;
    }
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${target.latitude},${target.longitude}&travelmode=driving',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps.')),
        );
      }
    }
  }

  void _save() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a location first.')),
      );
      return;
    }
    Navigator.of(context).pop(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Set location — ${widget.title}'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            markers: _markers,
            zoomControlsEnabled: false,
            initialCameraPosition: CameraPosition(
              target: _selected ?? const LatLng(33.6844, 73.0479), // fallback: Islamabad
              zoom: _selected == null ? 5 : 16,
            ),
            onMapCreated: (controller) => _mapController = controller,
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openPicker,
                    icon: const Icon(Icons.edit_location_alt),
                    label: const Text('Change Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3142),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 76),
        child: FloatingActionButton.extended(
          onPressed: _openDirections,
          backgroundColor: const Color(0xFF2D3142),
          icon: const Icon(Icons.directions, color: Colors.white),
          label: const Text(
            'Directions',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}