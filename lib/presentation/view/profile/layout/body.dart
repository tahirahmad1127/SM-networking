import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sm_networking/infrastructure/services/auth.dart';
import 'package:sm_networking/infrastructure/services/attendance.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/infrastructure/api_helper.dart';
import 'package:sm_networking/configurations/end_points.dart';
import 'package:sm_networking/application/cart_provider.dart';
import 'package:sm_networking/application/checkIn_provider.dart';
import 'package:sm_networking/application/visit_provider.dart';
import 'package:sm_networking/application/retailer_provider.dart';
import 'package:sm_networking/configurations/translation_helper.dart';
import 'package:sm_networking/infrastructure/model/user.dart';
import 'package:sm_networking/infrastructure/services/upload_file_services.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:sm_networking/presentation/elements/navigation_dialog.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';
import 'package:sm_networking/presentation/view/auth/log_in/log_in_view.dart';
import 'package:sm_networking/presentation/view/category_listing/category_listing_view.dart';
import 'package:sm_networking/presentation/view/map/map_retailers.dart';
import 'package:sm_networking/presentation/view/profile/my_recoveries_view.dart';
import 'package:sm_networking/presentation/view/profile/my_sales_view.dart';
import 'package:sm_networking/presentation/view/profile/layout/widgets/profile_card.dart';
import '../order_booker_reporting_view.dart';
import 'package:launch_review_latest/launch_review_latest.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../configurations/frontend_configs.dart';
import '../../../../infrastructure/services/retailers_cache.dart';
import '../../../elements/custom_text.dart';

class ProfileBody extends StatefulWidget {
  const ProfileBody({super.key});

  @override
  State<ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> {
  bool value = false;
  File? _image;
  bool isLoading = false;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = '${info.version}+${info.buildNumber}');
    }
  }

  @override
  Widget build(BuildContext context) {
    var user = Provider.of<UserProvider>(context);
    final role = user.getSalesUserDetails()?.role ?? '';
    final isTsm = role == 'warehouseManager' || role == 'orderBooker';

    return LoadingOverlay(
      isLoading: isLoading,
      progressIndicator: const ProcessingWidget(),
      color: Colors.transparent,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              children: [
                const SizedBox(height: 8),

                // ── Profile Card ────────────────────────────────────────────
                Container(
                  height: 97,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      borderRadius: FrontendConfigs.kAppBorder,
                      color: Colors.white),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 14.0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: _showImagePickerBottomSheet,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _image != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: Image.file(
                                  _image!,
                                  height: 55,
                                  width: 55,
                                  fit: BoxFit.cover,
                                ),
                              )
                                  : ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: ExtendedImage.network(
                                  user
                                      .getSalesUserDetails()!
                                      .user!
                                      .image
                                      .toString(),
                                  height: 55,
                                  width: 55,
                                  fit: BoxFit.fill,
                                  cache: true,
                                  loadStateChanged:
                                      (ExtendedImageState state) {
                                    switch (
                                    state.extendedImageLoadState) {
                                      case LoadState.loading:
                                        return ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(100),
                                          child: Image.asset(
                                            "assets/images/ph.jpeg",
                                            fit: BoxFit.fill,
                                            height: 55,
                                            width: 55,
                                          ),
                                        );
                                      case LoadState.failed:
                                        return ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(100),
                                          child: Image.asset(
                                            "assets/images/ph.jpeg",
                                            fit: BoxFit.fill,
                                            height: 55,
                                            width: 55,
                                          ),
                                        );
                                      default:
                                        return state.completedWidget;
                                    }
                                  },
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(30.0)),
                                ),
                              ),
                              Positioned(
                                bottom: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: FrontendConfigs.kPrimaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.pencil,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user
                                    .getSalesUserDetails()!
                                    .user!
                                    .name
                                    .toString(),
                                style: FrontendConfigs.kTitleStyle,
                                softWrap: true,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 3),
                              CustomText(
                                text: user
                                    .getSalesUserDetails()!
                                    .user!
                                    .phone
                                    .toString(),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ── App Version ──────────────────────────────────────────────
                if (_appVersion.isNotEmpty)
                  Center(
                    child: CustomText(
                      text: 'App Version: $_appVersion',
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),

                const SizedBox(height: 12),

                // ── My Recoveries ───────────────────────────────────────────
                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                            const MyRecoveriesView()));
                  },
                  child: ProfileCard(lebal: 'My Recoveries'),
                ),

                // ── OrderBookers Reporting (Warehouse Manager only) ───────
                if (role == 'warehouseManager') ...[
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: FrontendConfigs.kAppBorder,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const OrderBookersReportingView()));
                    },
                    child: ProfileCard(lebal: 'OrderBookers Reporting'),
                  ),

                  // ── My Sales (TSM's own Order Summary / Order Form /
                  // Overall Invoices — no distributor/order-booker filter) ──
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: FrontendConfigs.kAppBorder,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MySalesView()));
                    },
                    child: ProfileCard(lebal: 'My Sales'),
                  ),
                ],
                // ── Sales (Order Summary / Order Form / Overall Invoices) —
                // TSM only. orderBooker (and any other non-TSM role) doesn't
                // get this section at all. ─────────────────────────────────

                // ── Wholesalers (TSM only) ──────────────────────────────────
                // if (isTsm) ...[
                //   const SizedBox(height: 12),
                //   InkWell(
                //     borderRadius: FrontendConfigs.kAppBorder,
                //     onTap: () {
                //       Navigator.push(
                //           context,
                //           MaterialPageRoute(
                //               builder: (_) =>
                //               const WholesalerRetailerListView(
                //                   type: WholesalerRetailerType
                //                       .wholesaler)));
                //     },
                //     child: ProfileCard(lebal: 'Wholesalers'),
                //   ),
                // ],

                // ── Retailers (TSM only) ────────────────────────────────────
                // if (isTsm) ...[
                //   const SizedBox(height: 12),
                //   InkWell(
                //     borderRadius: FrontendConfigs.kAppBorder,
                //     onTap: () {
                //       Navigator.push(
                //           context,
                //           MaterialPageRoute(
                //               builder: (_) =>
                //               const WholesalerRetailerListView(
                //                   type:
                //                   WholesalerRetailerType.retailer)));
                //     },
                //     child: ProfileCard(lebal: 'Retailers'),
                //   ),
                // ],

                const SizedBox(height: 12),

                // ── Help & Support ──────────────────────────────────────────
                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () {
                    _launchUrl(
                        "https://wa.me/+923164936106?text=${Uri.parse("Welcome to SM Networking!")}");
                  },
                  child: ProfileCard(
                    lebal: TranslationHelper.getTranslatedText(
                        "help_support"),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Rate Our App ────────────────────────────────────────────
                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () {
                    LaunchReviewLatest.launch();
                  },
                  child: ProfileCard(
                    lebal: TranslationHelper.getTranslatedText(
                        "rate_our_app"),
                  ),
                ),

                const SizedBox(height: 12),

                // ── About Us ────────────────────────────────────────────────
                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () {
                    _launchUrl("https://karyana.co");
                  },
                  child: ProfileCard(lebal: 'About Us'),
                ),

                const SizedBox(height: 12),

                // ── Logout ──────────────────────────────────────────────────
                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () async {
                    SharedPreferences prefs =
                    await SharedPreferences.getInstance();
                    showNavigationDialog(context,
                        message:
                        "Do you really want to logout from app?",
                        buttonText: "Yes", navigation: () async {
                          final userDetails = context.mounted
                              ? Provider.of<UserProvider>(context, listen: false)
                              .getSalesUserDetails()
                              : null;
                          final userId = userDetails?.user?.id ?? '';

                          // ── Step 1: close out today's open attendance record, if any ──
                          try {
                            final openAttendanceId = await _findOpenAttendanceId();
                            if (openAttendanceId != null && openAttendanceId.isNotEmpty) {
                              await AttendanceRepositoryImp().checkOut(
                                openAttendanceId,
                                {'checkOutTime': DateTime.now().toIso8601String()},
                              );
                            }
                          } catch (_) {
                            // Attendance checkout failure shouldn't block logout.
                          }

                          // ── Step 2: clear the device lock on the backend ──
                          if (userId.isNotEmpty) {
                            try {
                              await AuthRepositoryImp().logout(userId: userId);
                            } catch (_) {
                              // Logout API failure shouldn't block local logout.
                            }
                          }

                          if (context.mounted) {
                            await Provider.of<CartProvider>(context,
                                listen: false)
                                .clearData();
                            await Provider.of<CheckInProvider>(context,
                                listen: false)
                                .clearData();
                            await Provider.of<VisitProvider>(context,
                                listen: false)
                                .clearVisitData();
                            Provider.of<UserProvider>(context,
                                listen: false)
                                .clearData();
                          }
                          await FirebaseAuth.instance.signOut();
                          prefs.clear();
                          await RetailerCacheService.clearRetailersCache();
                          await RetailerCacheService.clearBanksCache();
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                  const LogInView()),
                                  (route) => false);
                        },
                        secondButtonText: "No",
                        showSecondButton: true);
                  },
                  child: ProfileCard(
                    lebal:
                    TranslationHelper.getTranslatedText("logout"),
                    textColor: FrontendConfigs.kPrimaryColor,
                  ),
                ),

                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            CustomText(
              text: "Update profile photo",
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                  FrontendConfigs.kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.camera,
                    color: FrontendConfigs.kPrimaryColor),
              ),
              title: const Text('Camera',
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              subtitle: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndEdit(source: ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                  FrontendConfigs.kPrimaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(CupertinoIcons.photo,
                    color: FrontendConfigs.kPrimaryColor),
              ),
              title: const Text('Gallery',
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              subtitle: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndEdit(source: ImageSource.gallery);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndEdit({required ImageSource source}) async {
    final picker = ImagePicker();
    final pickedFile =
    await picker.pickImage(imageQuality: 60, source: source);
    if (pickedFile == null) return;
    final bytes = await File(pickedFile.path).readAsBytes();
    await _openProEditor(bytes);
  }

  Future<void> _openProEditor(Uint8List bytes) async {
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
      final dir = Directory.systemTemp;
      final path =
          '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressed = await FlutterImageCompress.compressWithList(
        result!,
        quality: 50,
        format: CompressFormat.jpeg,
      );
      final saved = await File(path).writeAsBytes(compressed);
      setState(() {
        _image = saved;
      });
      await _uploadProfilePicture(saved);
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    final userDetails = Provider.of<UserProvider>(context, listen: false)
        .getSalesUserDetails();
    final id = userDetails?.user?.id;
    final token = userDetails?.token ?? '';
    final role = userDetails?.role ?? '';

    if (id == null || id.isEmpty) return;

    final String endpoint;
    if (role == 'warehouseManager') {
      endpoint = ApiEndPoints.kUpdateWarehouseManagerProfilePicture + id;
    } else if (role == 'orderBooker') {
      endpoint = ApiEndPoints.kUpdateOrderBookerProfilePicture + id;
    } else {
      // Unknown role — no matching profile picture endpoint yet.
      return;
    }

    setState(() => isLoading = true);

    final result = await ApiBaseHelper().postMultiPartEither(
      endPoint: endpoint,
      isRequiredHeader: true,
      hasBody: false,
      hasFile: true,
      path: imageFile.path,
      header: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (mounted) setState(() => isLoading = false);

    result.fold(
          (l) {
        if (mounted) {
          getFlushBar(context,
              title: l.error ?? 'Failed to update profile photo');
        }
      },
          (r) {
        if (mounted) {
          getFlushBar(context, title: 'Profile photo updated successfully');
        }
      },
    );
  }

  /// Finds the currently open attendance record (checked in, not yet
  /// checked out), if any, regardless of role.
  ///
  /// - orderBooker / simple flow: a single 'attendanceId' key, gated by
  ///   'isCheckedIn' == true and no 'CHECK_OUT_TIME' saved yet.
  /// - warehouseManager flow: one 'wm_dist_{distributorId}' key per
  ///   distributor visited; at most one should be open (checkInTime set,
  ///   checkOutTime empty) at any given time.
  Future<String?> _findOpenAttendanceId() async {
    final prefs = await SharedPreferences.getInstance();

    // Simple / orderBooker pattern.
    final isCheckedIn = prefs.getBool('isCheckedIn') ?? false;
    final hasCheckOut = prefs.getString('CHECK_OUT_TIME') != null;
    final simpleId = prefs.getString('attendanceId');
    if (isCheckedIn && !hasCheckOut && simpleId != null && simpleId.isNotEmpty) {
      return simpleId;
    }

    // Per-distributor / warehouseManager pattern.
    for (final key in prefs.getKeys()) {
      if (!key.startsWith('wm_dist_')) continue;
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        final attendanceId = decoded['attendanceId'] as String? ?? '';
        final checkInTime = decoded['checkInTime'] as String? ?? '';
        final checkOutTime = decoded['checkOutTime'] as String? ?? '';
        if (attendanceId.isNotEmpty && checkInTime.isNotEmpty && checkOutTime.isEmpty) {
          return attendanceId;
        }
      } catch (_) {}
    }

    return null;
  }
}