// lib/presentation/view/attendance/layout/body.dart

import 'dart:async';
import 'dart:developer';
import 'dart:ui' as ui;
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/services/location.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:sm_networking/presentation/view/attendance/layout/widget/attendance_sheets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../../../application/attendance_bloc/attendance_bloc.dart';
import '../../../../application/checkIn_provider.dart';
import '../../../../application/tracking_bloc/tracking_bloc.dart';
import '../../../../infrastructure/model/attendance.dart';
import '../../../../infrastructure/services/background_location.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../../../../configurations/back_end_configs.dart';
import '../../../../infrastructure/services/permission_helper.dart';
import '../../../../infrastructure/services/work_manager.dart';

/// Renders [text] as plain, non-wrapping text when it fits the available
/// width; otherwise loops it in a horizontally-scrolling marquee so the
/// full value is still readable (used for the "Working under: {distributor}"
/// banner, where distributor names can run long).
class _AutoScrollText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _AutoScrollText({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: ui.TextDirection.ltr,
        )..layout();

        if (painter.width <= constraints.maxWidth) {
          return Text(text,
              style: style, maxLines: 1, overflow: TextOverflow.ellipsis);
        }

        return SizedBox(
          height: (style.fontSize ?? 13) + 4,
          child: Marquee(
            text: text,
            style: style,
            blankSpace: 40,
            velocity: 30,
            pauseAfterRound: const Duration(seconds: 1),
            fadingEdgeStartFraction: 0.05,
            fadingEdgeEndFraction: 0.05,
          ),
        );
      },
    );
  }
}

class AttendanceBody extends StatefulWidget {
  const AttendanceBody({super.key});

  @override
  State<AttendanceBody> createState() => _AttendanceBodyState();
}

class _AttendanceBodyState extends State<AttendanceBody>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {

  String? _lastAttendanceId;
  LatLng? currentLocation;

  Timer? _clockTimer;
  Timer? _refreshTimer;
  DateTime _currentTime = DateTime.now();

  bool _wasCheckedIn = false;

  // Covers the gap between the slide-to-check-in/out sheet closing and the
  // AttendanceBloc actually emitting AttendanceLoading — GPS fetch (and, for
  // check-in, the location-permission/distance work) happens in between
  // with no bloc state change to hang a loader off, which is exactly the
  // "no feedback while the app is clearly doing something" gap that made
  // this feel stuck.
  bool _isProcessingPunch = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late final AttendanceBloc _attendanceBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _attendanceBloc = context.read<AttendanceBloc>();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initialize();
    _startClock();

    // Load initial status
    Provider.of<CheckInProvider>(context, listen: false).loadStatus().then((_) {
      if (mounted) {
        _wasCheckedIn = Provider.of<CheckInProvider>(context, listen: false).isCheckedIn;
      }
    });

    // ✅ CRITICAL: Poll for state changes every 2 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;

      final provider = Provider.of<CheckInProvider>(context, listen: false);
      final wasCheckedInBefore = _wasCheckedIn;

      // ✅ Force reload from SharedPreferences
      await provider.forceReload();

      final isCheckedInNow = provider.isCheckedIn;

      // Detect auto-checkout
      if (wasCheckedInBefore && !isCheckedInNow) {
        debugPrint("🔔 Auto-checkout detected!");

        final prefs = await SharedPreferences.getInstance();
        final autoCheckoutTime = prefs.getString('autoCheckoutTimestamp');

        if (autoCheckoutTime != null && mounted) {
          final formattedTime = DateFormat('hh:mm a').format(DateTime.parse(autoCheckoutTime));
          getFlushBar(context, title: "You were auto-checked out at $formattedTime");
          await prefs.remove('autoCheckoutTimestamp');
        }

        // ✅ FORCE IMMEDIATE UI UPDATE
        if (mounted) setState(() {});
      }

      _wasCheckedIn = isCheckedInNow;
    });

    _resetIfNewDay().then((_) {
      _loadDynamicTimes();
      _loadAttendanceData();
      _checkPendingCheckout();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _handleAppResume();
    }
  }

  Future<void> _handleAppResume() async {
    debugPrint("📱 App resumed, checking for updates...");

    final prefs = await SharedPreferences.getInstance();
    final provider = Provider.of<CheckInProvider>(context, listen: false);

    // Force reload state from disk
    await provider.forceReload();

    final autoCheckoutTime = prefs.getString('autoCheckoutTimestamp');
    if (autoCheckoutTime != null && mounted) {
      debugPrint("🔄 Auto-checkout detected on resume");

      final formattedTime = DateFormat('hh:mm a').format(DateTime.parse(autoCheckoutTime));
      getFlushBar(context, title: "You were auto-checked out at $formattedTime");

      await prefs.remove('autoCheckoutTimestamp');
    }

    // Update tracked state
    if (mounted) {
      _wasCheckedIn = provider.isCheckedIn;
      setState(() {}); // Force UI rebuild
    }

    await _checkIfAutoCheckedOut();
  }

  Future<void> _checkIfAutoCheckedOut() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAuto = prefs.getString('lastAutoCheckout');

    if (lastAuto != null && mounted) {
      final diff = DateTime.now().difference(DateTime.parse(lastAuto)).inMinutes;
      if (diff < 2) {
        final savedOut = prefs.getString('CHECK_OUT_TIME');
        if (savedOut != null) {
          final formattedTime = DateFormat('hh:mm a').format(DateTime.parse(savedOut));
          getFlushBar(context, title: "Auto-checked out at $formattedTime");
        }
        await prefs.remove('lastAutoCheckout');
      }
    }
  }

  Future<void> _checkPendingCheckout() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingId = prefs.getString('pending_checkout');
    final pendingTime = prefs.getString('pending_checkout_time');

    if (pendingId != null && pendingTime != null && mounted) {
      try {
        final attendance = AttendanceModel(checkOutTime: pendingTime);
        _attendanceBloc.add(CheckOutEvent(pendingId, attendance.toJson()));
        await prefs.remove('pending_checkout');
        await prefs.remove('pending_checkout_time');
        debugPrint("✅ Pending checkout synced successfully");

        if (mounted) {
          await Provider.of<CheckInProvider>(context, listen: false).forceReload();
        }
      } catch (e) {
        debugPrint("❌ Failed to sync pending checkout: $e");
      }
    }
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  Future<void> _initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

    AwesomeNotifications().isNotificationAllowed().then((allowed) {
      if (!allowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    await _fetchCurrentLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _clockTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    final loc = await LocationService.getCurrentLatLng(context);
    if (loc != null && mounted) {
      setState(() => currentLocation = loc);
    }
  }

  Future<void> _showPunchNotification(String title, String body) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'basic_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        wakeUpScreen: true,
      ),
    );
  }

  Future<void> _scheduleBackgroundTasks() async {
    final provider = Provider.of<CheckInProvider>(context, listen: false);
    final checkoutTime = provider.checkOutDateTime;
    if (checkoutTime == null) return;

    final now = DateTime.now();
    await Workmanager().cancelAll();

    final thirtyBefore = checkoutTime.subtract(const Duration(minutes: 30));
    final fifteenBefore = checkoutTime.subtract(const Duration(minutes: 15));

    if (now.isBefore(thirtyBefore)) {
      await Workmanager().registerOneOffTask(
        "reminder_30", "reminder_30",
        initialDelay: thirtyBefore.difference(now),
      );
    }
    if (now.isBefore(fifteenBefore)) {
      await Workmanager().registerOneOffTask(
        "reminder_15", "reminder_15",
        initialDelay: fifteenBefore.difference(now),
      );
    }

    final delay = now.isBefore(checkoutTime)
        ? checkoutTime.difference(now)
        : const Duration(seconds: 10);

    await Workmanager().registerOneOffTask(
      "auto_checkout", "auto_checkout",
      initialDelay: delay,
    );

    await Workmanager().registerPeriodicTask(
      "periodic_check", "auto_checkout",
      frequency: const Duration(minutes: 15),
    );
  }

  void _showCheckInSheet(BuildContext context) async {
    final provider = Provider.of<CheckInProvider>(context, listen: false);

    if (!provider.canCheckIn) {
      getFlushBar(context, title: provider.checkInStatusMessage);
      return;
    }

    // REQUEST PERMISSIONS BEFORE SHOWING SHEET
    final hasPermission = await PermissionHelper.requestBackgroundLocationPermission(context);
    if (!hasPermission) {
      if (mounted) {
        getFlushBar(context, title: "Location permissions are required for attendance tracking");
      }
      return;
    }

    // NOW SHOW THE SHEET
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SlideToCheckInSheet(
        onComplete: () async {
          Navigator.pop(context);

          if (!mounted) return;
          setState(() => _isProcessingPunch = true);

          await _fetchCurrentLocation();
          if (!mounted) return;

          final user = Provider.of<UserProvider>(context, listen: false);
          final userId = user.getSalesUserDetails()?.user?.id;
          if (userId == null) {
            debugPrint("❌ No userId found");
            setState(() => _isProcessingPunch = false);
            return;
          }

          final now = DateTime.now();
          final attendance = AttendanceModel(
            salesPersonId: userId,
            lat: currentLocation?.latitude,
            lng: currentLocation?.longitude,
            checkInTime: now.toIso8601String(),
            date: DateFormat('yyyy-MM-dd').format(now),
          );

          // ✅ ONLY send check-in request
          // All tracking services will be started in the BLoC listener AFTER successful response
          log("⏳ Sending check-in request to server...");
          context.read<AttendanceBloc>().add(CheckInEvent(attendance.toJson()));
        },
      ),
    );
  }

  // ── Haversine distance (metres) ──────────────────────────────────────────────
  double _haversineDistance(LatLng a, LatLng b) {
    const R = 6371000.0;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final lat1 = a.latitude * math.pi / 180;
    final lat2 = b.latitude * math.pi / 180;
    final sinLat = math.sin(dLat / 2);
    final sinLng = math.sin(dLng / 2);
    final x = sinLat * sinLat + math.cos(lat1) * math.cos(lat2) * sinLng * sinLng;
    return R * 2 * math.asin(math.sqrt(x.clamp(0.0, 1.0)));
  }

  /// Fetches the distributor shopLocation from API.
  /// Returns null if coordinates are not set.
  Future<LatLng?> _fetchDistributorLocation(String distributorId, String token) async {
    try {
      final rawToken = token.startsWith('Bearer ') ? token.substring(7) : token;
      final uri = Uri.parse('${BackendConfigs.apiUrl}sale-user/$distributorId');
      final response = await http.get(uri, headers: {
        'Accept': 'application/json',
        'x-auth-token': rawToken,
      });
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final shopLocation = decoded['data']?['shopLocation'];
        final lat = shopLocation?['lat'];
        final lng = shopLocation?['lng'];
        if (lat != null && lng != null) {
          return LatLng((lat as num).toDouble(), (lng as num).toDouble());
        }
      }
      debugPrint('⚠️ Distributor has no saved shopLocation');
      return null;
    } catch (e) {
      debugPrint('❌ Failed to fetch distributor location: $e');
      return null;
    }
  }

  void _showCheckOutSheet(BuildContext context) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final role = user.getSalesUserDetails()?.role ?? '';

    // ── OrderBooker only: must be within 20m of their distributor ────────────
    if (role == 'orderBooker') {
      await _fetchCurrentLocation();

      if (currentLocation == null) {
        if (mounted) {
          getFlushBar(context,
              title: "Cannot determine your location. Please enable GPS and try again.");
        }
        return;
      }

      final distributorId =
      (user.getSalesUserDetails()?.user?.distributor ?? '').trim();
      final token = user.getSalesUserDetails()?.token ?? '';

      debugPrint("🔍 OrderBooker distributorId: '$distributorId'");
      debugPrint("🔍 User object: \${user.getSalesUserDetails()?.user?.toString()}");

      if (distributorId.isEmpty) {
        if (mounted) {
          getFlushBar(context,
              title: "No distributor assigned. Please contact your administrator.");
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verifying your location..."),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final distributorLocation =
      await _fetchDistributorLocation(distributorId, token);

      if (!mounted) return;

      if (distributorLocation == null) {
        // Distributor has no GPS coordinates saved — allow checkout with log
        debugPrint("⚠️ Distributor has no location set — checkout allowed");
      } else {
        final distance =
        _haversineDistance(currentLocation!, distributorLocation);
        debugPrint(
            "📍 Distance from distributor: ${distance.toStringAsFixed(1)}m");

        if (distance > 20) {
          if (mounted) {
            getFlushBar(context,
                title:
                "You must be within 20m of your distributor to check out. "
                    "You are ${distance.toStringAsFixed(0)}m away.");
          }
          return;
        }
      }
    }
    // ─────────────────────────────────────────────────────────────────────────

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SlideToCheckOutSheet(
        onComplete: () {
          Navigator.pop(context);
          if (mounted) setState(() => _isProcessingPunch = true);

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted || _lastAttendanceId == null) {
              if (mounted) setState(() => _isProcessingPunch = false);
              return;
            }

            final now = DateTime.now();

            context.read<AttendanceBloc>().add(CheckOutEvent(
              _lastAttendanceId!,
              AttendanceModel(checkOutTime: now.toIso8601String()).toJson(),
            ));

            // STOP Foreground SERVICE
            await LocationService.stopUserLiveTracking(
              trackingBloc: context.read<TrackingBloc>(),
            );

            // STOP BACKGROUND SERVICE
            await BackgroundLocationService.stopTracking();

            await Provider.of<CheckInProvider>(context, listen: false).checkOut();
            _wasCheckedIn = false;
            await Workmanager().cancelAll();
          });
        },
      ),
    );
  }

  void _loadDynamicTimes() async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final checkInProvider = Provider.of<CheckInProvider>(context, listen: false);

    final userDetails = user.getSalesUserDetails()?.user;
    if (userDetails != null) {
      final checkInTime = userDetails.checkInTime ?? "09:00";
      final checkOutTime = userDetails.checkOutTime ?? "17:00";

      checkInProvider.setAllowedTimes(
        checkInTime: checkInTime,
        checkOutTime: checkOutTime,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ALLOWED_CHECKOUT_TIME', checkOutTime);
    }
  }

  String _formatTimeForDisplay(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return timeStr;
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeStr;
    }
  }

  Future<void> _loadAttendanceData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('attendanceId');
    if (savedId != null) {
      _lastAttendanceId = savedId;
    }

    await Provider.of<CheckInProvider>(context, listen: false).forceReload();

    final isCheckedIn = prefs.getBool('isCheckedIn') ?? false;
    final hasCheckOut = prefs.getString('CHECK_OUT_TIME') != null;

    if (isCheckedIn && !hasCheckOut) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final userId = Provider.of<UserProvider>(context, listen: false).getSalesUserDetails()?.user?.id;

        // Restart foreground tracking
        if (userId != null && !LocationService.isUserLiveTrackingActive()) {
          await LocationService.startUserLiveTracking(
            context: context,
            userId: userId,
            trackingBloc: context.read<TrackingBloc>(),
          );
        }

        // Restart background service
        await BackgroundLocationService.startTracking(userId!);

        await _scheduleBackgroundTasks();
      });
    }
  }

  Future<void> _resetIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('lastSavedDate');
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (lastDate != today) {
      await prefs.remove('CHECK_IN_TIME');
      await prefs.remove('CHECK_OUT_TIME');
      await prefs.remove('isCheckedIn');
      await prefs.remove('attendanceId');
      await prefs.remove('lastAutoCheckout');
      await prefs.remove('autoCheckoutTimestamp');
      await prefs.remove('pending_checkout');
      await prefs.remove('pending_checkout_time');
      await prefs.setString('lastSavedDate', today);
      await Workmanager().cancelAll();

      if (mounted) {
        await Provider.of<CheckInProvider>(context, listen: false).clearData();
        _wasCheckedIn = false;
      }
    }
  }

  /// ✅ CRITICAL: Start tracking services helper method
  Future<void> _startTrackingServices(String userId) async {
    try {
      log("🟢 Starting foreground live tracking");
      await LocationService.startUserLiveTracking(
        context: context,
        userId: userId,
        trackingBloc: context.read<TrackingBloc>(),
      );
      log("✅ Foreground tracking started");

      // Additional delay before background service
      log("⏳ Preparing background service...");
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // START BACKGROUND SERVICE (for when app is closed)
      log("🚀 Starting background location service for user: $userId");
      await BackgroundLocationService.startTracking(userId);
      log("✅ Background service started successfully");

    } catch (e, s) {
      log("❌ Failed to start tracking services: $e");
      log("Stack trace: $s");

      if (mounted) {
        getFlushBar(context,
            title: "Check-in successful, but tracking service failed. Please restart the app."
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context);
    final checkInProvider = Provider.of<CheckInProvider>(context);

    // Session can be cleared out from under this screen mid-build (forced
    // logout on a 401) — the header below assumes a non-null user, so bail
    // out to a harmless placeholder for that one frame instead of crashing.
    if (user.getSalesUserDetails()?.user == null) {
      return const SizedBox.shrink();
    }

    return BlocConsumer<AttendanceBloc, AttendanceState>(
      listener: (context, state) async {
        if (state is AttendanceLoaded) {
          final prefs = await SharedPreferences.getInstance();
          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final timeNow = DateFormat('hh:mm a').format(DateTime.now());

          if (state.isCheckIn) {
            // ✅ CHECK-IN SUCCESSFUL - Now start tracking services
            log("✅ Check-in API succeeded, proceeding with setup...");

            _lastAttendanceId = state.model.id;
            await prefs.setString('attendanceId', state.model.id ?? '');
            await prefs.setBool('isCheckedIn', true);
            await prefs.setString('lastSavedDate', today);

            await checkInProvider.checkIn();
            _wasCheckedIn = true;

            // ✅ NOW start tracking services (only on API success)
            final userId = user.getSalesUserDetails()?.user?.id;
            if (userId != null) {
              await _startTrackingServices(userId);
            } else {
              log("❌ Cannot start tracking: userId is null");
            }

            await _showPunchNotification('Checked In Successfully', 'You checked in at $timeNow');
            await _scheduleBackgroundTasks();

            if (mounted) {
              getFlushBar(context, title: "✅ Checked in successfully");
            }
          } else {
            // CHECK-OUT SUCCESSFUL
            log("✅ Check-out API succeeded");
            await checkInProvider.checkOut();
            _wasCheckedIn = false;
            await _showPunchNotification('Checked Out', 'You checked out at $timeNow');
            await Workmanager().cancelAll();
          }
          if (mounted) setState(() => _isProcessingPunch = false);
        } else if (state is AttendanceFailed) {
          // ❌ CHECK-IN/OUT FAILED - Show error, DON'T start tracking
          log("❌ Attendance operation failed: ${state.message}");
          getFlushBar(context, title: state.message);

          // Ensure we don't have stale check-in state
          if (mounted) {
            final provider = Provider.of<CheckInProvider>(context, listen: false);
            await provider.forceReload();
          }
          if (mounted) setState(() => _isProcessingPunch = false);
        }
      },
      builder: (context, state) {
        if (state is AttendanceLoading || _isProcessingPunch) {
          return const Center(child: ProcessingWidget());
        }

        final timeFormat = DateFormat('hh:mm a');
        final dateFormat = DateFormat('MMM dd, yyyy - EEEE');

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              text: "Welcome Back!",
                              fontSize: 18,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: CustomText(
                                text: user.getSalesUserDetails()?.user?.name ?? 'User',
                                fontWeight: FontWeight.w700,
                                fontSize: 24,
                                overflow: TextOverflow.ellipsis,
                                color: const Color(0xFF2D3142),
                              ),
                            ),
                            const SizedBox(height: 4),
                            CustomText(
                              text: DateFormat.yMMMMEEEEd().format(DateTime.now()),
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            // ── Assigned distributor (orderBooker only) ──────
                            // sale-user/login currently returns `distributor`
                            // as a bare ID, not populated with a name — see
                            // the note on User.distributorName. Nothing shows
                            // here until the backend populates it.
                            if (user.getSalesUserDetails()?.role == 'orderBooker' &&
                                (user.getSalesUserDetails()?.user?.distributorName ?? '')
                                    .isNotEmpty) ...[
                              const SizedBox(height: 8),
                              // Bounded width, same as the name field above —
                              // this Column is a plain (non-flex) child of the
                              // outer spaceBetween Row, so Flutter gives it an
                              // UNBOUNDED width by design (Row only bounds
                              // Expanded/Flexible children). A Flexible/Expanded
                              // inside an unbounded-width Row crashes
                              // ("incoming width constraints are unbounded"),
                              // so this must be explicitly sized instead.
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.6,
                                child: Row(
                                  children: [
                                    Icon(Icons.storefront_outlined,
                                        size: 15, color: FrontendConfigs.kPrimaryColor),
                                    const SizedBox(width: 4),
                                    CustomText(
                                      text: "Working under:",
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: FrontendConfigs.kPrimaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: _AutoScrollText(
                                        text: user
                                            .getSalesUserDetails()!
                                            .user!
                                            .distributorName!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: FrontendConfigs.kPrimaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.grey.shade300,
                          foregroundImage: (user.getSalesUserDetails()?.user?.image ?? '').isNotEmpty
                              ? NetworkImage(user.getSalesUserDetails()!.user!.image!)
                              : null,
                          child: (user.getSalesUserDetails()?.user?.image ?? '').isNotEmpty
                              ? null
                              : const Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Column(
                      children: [
                        CustomText(
                          text: timeFormat.format(_currentTime).toUpperCase(),
                          fontSize: 60,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF2D3142),
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                          text: dateFormat.format(_currentTime),
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 70),
                  Center(
                    child: GestureDetector(
                      onTap: () => checkInProvider.isCheckedIn
                          ? _showCheckOutSheet(context)
                          : _showCheckInSheet(context),
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: checkInProvider.isCheckedIn ? 1.0 : _pulseAnimation.value,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.grey.shade100, Colors.grey.shade200],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade300,
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(25),
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/icons/bottom_navigation_icons/punching_icon.png',
                                      height: 50,
                                      color: checkInProvider.isCheckedIn
                                          ? FrontendConfigs.kPrimaryColor
                                          : FrontendConfigs.kGreenColor,
                                    ),
                                    const SizedBox(height: 8),
                                    CustomText(
                                      text: checkInProvider.isCheckedIn ? "Check Out" : "Check In",
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: checkInProvider.isCheckedIn
                                          ? FrontendConfigs.kPrimaryColor
                                          : FrontendConfigs.kGreenColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                          icon: Icons.login_rounded,
                          label: "Check In",
                          value: checkInProvider.formattedCheckInTime,
                          color: FrontendConfigs.kPrimaryColor,
                        ),
                        _buildStatCard(
                          icon: Icons.logout_rounded,
                          label: "Check Out",
                          value: checkInProvider.formattedCheckOutTime,
                          color: Colors.orange,
                        ),
                        _buildStatCard(
                          icon: Icons.access_time_rounded,
                          label: "Total Hrs",
                          value: checkInProvider.totalHours,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 8),
        CustomText(
          text: value,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: const Color(0xFF2D3142),
        ),
        const SizedBox(height: 2),
        CustomText(
          text: label,
          fontSize: 11,
          color: Colors.grey.shade500,
        ),
      ],
    );
  }
}