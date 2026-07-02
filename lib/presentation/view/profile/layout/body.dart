import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sm_networking/configurations/back_end_configs.dart';
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
import 'package:sm_networking/presentation/view/profile/layout/widgets/profile_card.dart';
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

                const SizedBox(height: 12),

                // ── Generate Order Summary ───────────────────────────────────
                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () => _showReportDateSheet(
                    buttonLabel: 'Generate Order Summary',
                    useDateRange: true,
                    onGenerate: _generateOrderSummary,
                  ),
                  child: ProfileCard(lebal: 'Generate Order Summary'),
                ),

                const SizedBox(height: 12),

                // ── Generate Order Form ──────────────────────────────────────
                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () => _showReportDateSheet(
                    buttonLabel: 'Generate Order Form',
                    useDateRange: true,
                    onGenerate: _generateOrderForm,
                  ),
                  child: ProfileCard(lebal: 'Generate Order Form'),
                ),

                const SizedBox(height: 12),

                // ── Generate Overall Invoices ────────────────────────────────
                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () => _showReportDateSheet(
                    buttonLabel: 'Generate Overall Invoices',
                    useDateRange: true,
                    onGenerate: _generateInvoices,
                  ),
                  child: ProfileCard(lebal: 'Generate Overall Invoices'),
                ),

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

  // ── Reports (Order Summary / Order Form / Overall Invoices) ─────────────────

  /// Maps the app's internal role string to the value the backend expects
  /// for `userType`. ASSUMPTION: anything containing "order"/"booker" is
  /// treated as "Order Booker", everything else (including warehouseManager)
  /// falls back to "TSM" — confirm this mapping is correct for all roles.
  String _mapUserTypeForReports(String role) {
    final r = role.toLowerCase();
    if (r.contains('order') || r.contains('booker')) return 'Order Booker';
    return 'TSM';
  }

  Future<void> _openPdf(String url) async {
    try {
      await _launchUrl(url);
    } catch (_) {
      if (mounted) getFlushBar(context, title: 'Could not open the PDF.');
    }
  }

  /// If there's more than one invoice link, let the user pick which to open
  /// (url_launcher can only open one at a time).
  Future<void> _showInvoiceLinksSheet(List<String> urls) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            CustomText(
              text: "${urls.length} invoices found",
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            const SizedBox(height: 8),
            ...List.generate(urls.length, (i) {
              return ListTile(
                leading: Icon(Icons.picture_as_pdf_outlined,
                    color: FrontendConfigs.kPrimaryColor),
                title: Text('Invoice ${i + 1}'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _openPdf(urls[i]),
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// Shared date-picker bottom sheet used by all 3 report actions.
  /// [useDateRange] = true shows Start + End Date fields; false shows a
  /// single Date field (used for Overall Invoices, which only takes `date`).
  void _showReportDateSheet({
    required String buttonLabel,
    required bool useDateRange,
    required Future<void> Function(DateTime start, DateTime? end) onGenerate,
  }) {
    DateTime? startDate;
    DateTime? endDate;
    bool isGenerating = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            Future<void> pickDate(bool isStart) async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: sheetContext,
                initialDate: now,
                firstDate: DateTime(now.year - 3),
                lastDate: now,
              );
              if (picked == null) return;
              setSheetState(() {
                if (isStart) {
                  startDate = picked;
                } else {
                  endDate = picked;
                }
              });
            }

            Future<void> handleGenerate() async {
              if (startDate == null || (useDateRange && endDate == null)) {
                getFlushBar(sheetContext,
                    title: 'Please select the required date(s)');
                return;
              }
              if (useDateRange && endDate!.isBefore(startDate!)) {
                getFlushBar(sheetContext,
                    title: 'End date cannot be before start date');
                return;
              }
              setSheetState(() => isGenerating = true);
              try {
                await onGenerate(startDate!, useDateRange ? endDate : null);
              } finally {
                if (mounted) setSheetState(() => isGenerating = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    CustomText(
                      text: buttonLabel,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 20),
                    if (useDateRange)
                      Row(
                        children: [
                          Expanded(
                            child: _ReportDateField(
                              label: 'Start Date',
                              value: startDate,
                              onTap: () => pickDate(true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ReportDateField(
                              label: 'End Date',
                              value: endDate,
                              onTap: () => pickDate(false),
                            ),
                          ),
                        ],
                      )
                    else
                      _ReportDateField(
                        label: 'Date',
                        value: startDate,
                        onTap: () => pickDate(true),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isGenerating ? null : handleGenerate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FrontendConfigs.kPrimaryColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isGenerating
                            ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          buttonLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Map<String, String> _reportHeaders(String token) {
    final rawToken = token.startsWith('Bearer ') ? token.substring(7) : token;
    return {
      'Content-Type': 'application/json',
      'x-auth-token': rawToken,
    };
  }

  /// NOTE: /api/order/by-salesperson-date currently returns raw JSON order
  /// data (for rendering a summary grid), not a `pdfUrl` — per your backend
  /// dev's own spec. This is wired up assuming a `data.pdfUrl` field gets
  /// added later, mirroring _generateOrderForm exactly. Until then, this
  /// will show a "not available yet" message instead of a PDF.
  Future<void> _generateOrderSummary(DateTime start, DateTime? end) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final details = user.getSalesUserDetails();
    final salePersonId = details?.user?.id ?? '';
    final token = details?.token ?? '';
    final userType = _mapUserTypeForReports(details?.role ?? '');

    try {
      final uri = Uri.parse('${BackendConfigs.apiUrl}order/by-salesperson-date');
      final response = await http.post(
        uri,
        headers: _reportHeaders(token),
        body: jsonEncode({
          'salePerson': salePersonId,
          'userType': userType,
          'startDate': DateFormat('yyyy-MM-dd').format(start),
          'endDate': DateFormat('yyyy-MM-dd').format(end ?? start),
        }),
      );

      if (response.statusCode != 200) {
        if (mounted) {
          getFlushBar(context,
              title: 'Failed to generate order summary: ${_extractErrorMessage(response)}');
        }
        return;
      }

      final decoded = jsonDecode(response.body);
      // NOTE: unlike order/load-form, this endpoint returns pdfUrl at the
      // top level (data is the raw orders array), per backend dev's update.
      final pdfUrl = decoded['pdfUrl'];

      if (!mounted) return;
      if (pdfUrl != null && pdfUrl.toString().isNotEmpty) {
        Navigator.pop(context); // close the sheet
        await _openPdf(pdfUrl.toString());
      } else {
        getFlushBar(context, title: 'No orders found for the selected dates.');
      }
    } catch (e) {
      if (mounted) {
        getFlushBar(context, title: 'Something went wrong. Please try again.');
      }
    }
  }

  Future<void> _generateOrderForm(DateTime start, DateTime? end) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final details = user.getSalesUserDetails();
    final salePersonId = details?.user?.id ?? '';
    final token = details?.token ?? '';
    final userType = _mapUserTypeForReports(details?.role ?? '');

    try {
      final uri = Uri.parse('${BackendConfigs.apiUrl}order/load-form');
      final response = await http.post(
        uri,
        headers: _reportHeaders(token),
        body: jsonEncode({
          'salePerson': salePersonId,
          'userType': userType,
          'startDate': DateFormat('yyyy-MM-dd').format(start),
          'endDate': DateFormat('yyyy-MM-dd').format(end ?? start),
        }),
      );

      if (response.statusCode != 200) {
        if (mounted) {
          getFlushBar(context,
              title: 'Failed to generate order form: ${_extractErrorMessage(response)}');
        }
        return;
      }

      final decoded = jsonDecode(response.body);
      final pdfUrl = decoded['data']?['pdfUrl'];

      if (!mounted) return;
      if (pdfUrl != null && pdfUrl.toString().isNotEmpty) {
        Navigator.pop(context); // close the sheet
        await _openPdf(pdfUrl.toString());
      } else {
        getFlushBar(context, title: 'No orders found for the selected dates.');
      }
    } catch (e) {
      if (mounted) {
        getFlushBar(context, title: 'Something went wrong. Please try again.');
      }
    }
  }

  /// Extracts a human-readable error message from a failed response body,
  /// falling back to the raw status code if the body isn't JSON/expected shape.
  String _extractErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final msg = decoded['msg'] ?? decoded['message'] ?? decoded['error'];
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString();
        }
      }
    } catch (_) {
      // response wasn't JSON — fall through to generic message below
    }
    return 'Server returned ${response.statusCode}.';
  }

  /// Backend's /api/order/report only accepts a single `date`, so for a
  /// selected range we call it once per day and merge all the returned
  /// invoice links together.
  Future<void> _generateInvoices(DateTime start, DateTime? end) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final details = user.getSalesUserDetails();
    final salePersonId = details?.user?.id ?? '';
    final token = details?.token ?? '';

    final rangeEnd = end ?? start;
    final days = <DateTime>[];
    for (var d = start;
    !d.isAfter(rangeEnd);
    d = d.add(const Duration(days: 1))) {
      days.add(d);
    }

    final allUrls = <String>[];
    String? lastError;

    try {
      final uri = Uri.parse('${BackendConfigs.apiUrl}order/report');

      for (final day in days) {
        final response = await http.post(
          uri,
          headers: _reportHeaders(token),
          body: jsonEncode({
            'date': DateFormat('yyyy-MM-dd').format(day),
            'salePerson': salePersonId,
          }),
        );

        if (response.statusCode != 200) {
          lastError = _extractErrorMessage(response);
          continue; // keep trying the remaining days
        }

        final decoded = jsonDecode(response.body);
        final urls = (decoded['data'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty);
        allUrls.addAll(urls);
      }

      if (!mounted) return;

      if (allUrls.isEmpty) {
        getFlushBar(
          context,
          title: lastError != null
              ? 'Failed to generate invoices: $lastError'
              : 'No invoices found for the selected dates.',
        );
        return;
      }

      Navigator.pop(context); // close the sheet
      if (allUrls.length == 1) {
        await _openPdf(allUrls.first);
      } else {
        await _showInvoiceLinksSheet(allUrls);
      }
    } catch (e) {
      if (mounted) {
        getFlushBar(context, title: 'Something went wrong. Please try again.');
      }
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

// ── Date input box used in the report-generation bottom sheets ──────────────
// Styled to match the "mm/dd/yyyy" boxed date picker shown in the reference
// screenshot.
class _ReportDateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _ReportDateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'mm/dd/yyyy'
        : DateFormat('MM/dd/yyyy').format(value!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: label,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: FrontendConfigs.kTextFieldColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    color: value == null
                        ? Colors.grey.shade500
                        : Colors.black87,
                  ),
                ),
                Icon(Icons.calendar_today_outlined,
                    size: 17, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }
}