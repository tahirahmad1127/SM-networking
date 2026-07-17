import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/back_end_configs.dart';
import 'package:sm_networking/infrastructure/model/order.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:sm_networking/presentation/elements/order_summary_table_view.dart';
import 'package:sm_networking/presentation/view/profile/layout/widgets/profile_card.dart';

import '../../../configurations/frontend_configs.dart';
import '../../elements/custom_text.dart';
import '../../elements/pdf_viewer_view.dart';

/// "My Sales" — the same three report actions as [SalesView] (Order Summary
/// / Order Form / Overall Invoices), but scoped to the logged-in TSM's own
/// orders across ALL their distributors/order-bookers. Unlike [SalesView]
/// (reached via "OrderBookers Reporting" → "Sales"), this doesn't ask for a
/// distributor/order-booker filter — the report is always "everything I
/// (this TSM) placed", so only a date range is needed.
///
/// Hits the exact same endpoints as [SalesView] with the same response
/// shapes; the only difference in the request body is that `distributorId`
/// / `orderBookerId` is never included.
class MySalesView extends StatefulWidget {
  const MySalesView({super.key});

  @override
  State<MySalesView> createState() => _MySalesViewState();
}

class _MySalesViewState extends State<MySalesView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: CustomText(
          text: 'My Sales',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              children: [
                const SizedBox(height: 8),

                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () => _showDateRangeSheet(
                    context: context,
                    buttonLabel: 'Generate Order Summary',
                    onGenerate: _generateOrderSummary,
                  ),
                  child: ProfileCard(lebal: 'Generate Order Summary'),
                ),

                const SizedBox(height: 12),

                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () => _showDateRangeSheet(
                    context: context,
                    buttonLabel: 'Generate Order Form',
                    onGenerate: _generateOrderForm,
                  ),
                  child: ProfileCard(lebal: 'Generate Order Form'),
                ),

                const SizedBox(height: 12),

                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () => _showDateRangeSheet(
                    context: context,
                    buttonLabel: 'Generate Overall Invoices',
                    onGenerate: _generateInvoices,
                  ),
                  child: ProfileCard(lebal: 'Generate Overall Invoices'),
                ),

                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── shared helpers ─────────────────────────────────────────────────────

  Map<String, String> _reportHeaders(String token) {
    final rawToken = token.startsWith('Bearer ') ? token.substring(7) : token;
    return {
      'Content-Type': 'application/json',
      'x-auth-token': rawToken,
    };
  }

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

  void _openPdf(String url, {required String title}) {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerView(pdfUrl: url, title: title),
      ),
    );
  }

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
                onTap: () {
                  Navigator.pop(context); // close the sheet
                  _openPdf(urls[i], title: 'Invoice ${i + 1}');
                },
              );
            }),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ── report generation — always "my" data, no entity filter ────────────

  Future<void> _generateOrderSummary(DateTime start, DateTime? end) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final details = user.getSalesUserDetails();
    final salePersonId = details?.user?.id ?? '';
    final token = details?.token ?? '';

    if (salePersonId.isEmpty) {
      if (mounted) {
        getFlushBar(context,
            title:
            'Your session is missing required user info. Please log out and log back in.');
      }
      return;
    }

    try {
      final uri =
      Uri.parse('${BackendConfigs.apiUrl}order/by-salesperson-date');
      final response = await http.post(
        uri,
        headers: _reportHeaders(token),
        body: jsonEncode({
          'salePerson': salePersonId,
          'userType': 'TSM',
          'startDate': DateFormat('yyyy-MM-dd').format(start),
          'endDate': DateFormat('yyyy-MM-dd').format(end ?? start),
        }),
      );

      if (response.statusCode != 200) {
        if (mounted) {
          getFlushBar(context,
              title:
              'Failed to generate order summary: ${_extractErrorMessage(response)}');
        }
        return;
      }

      final decoded = jsonDecode(response.body);
      final orders = _extractOrders(decoded);

      if (orders.isEmpty) {
        if (mounted) {
          getFlushBar(context, title: 'No orders found for the selected dates.');
        }
        return;
      }

      if (!mounted) return;
      Navigator.pop(context); // close the filter sheet
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderSummaryTableView(
            orders: orders,
            startDate: start,
            endDate: end,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        getFlushBar(context, title: 'Something went wrong. Please try again.');
      }
    }
  }

  /// order/by-salesperson-date's exact response shape isn't nailed down
  /// (raw JSON, not a file) — accepts a bare list, or a map wrapping the
  /// list under `data`/`orders`/`result`.
  List<OrderModel> _extractOrders(dynamic decoded) {
    dynamic raw = decoded;
    if (raw is Map) {
      raw = raw['data'] ?? raw['orders'] ?? raw['result'] ?? raw;
    }
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _generateOrderForm(DateTime start, DateTime? end) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final details = user.getSalesUserDetails();
    final salePersonId = details?.user?.id ?? '';
    final token = details?.token ?? '';

    if (salePersonId.isEmpty) {
      if (mounted) {
        getFlushBar(context,
            title:
            'Your session is missing required user info. Please log out and log back in.');
      }
      return;
    }

    try {
      final uri = Uri.parse('${BackendConfigs.apiUrl}order/load-form');
      final response = await http.post(
        uri,
        headers: _reportHeaders(token),
        body: jsonEncode({
          'salePerson': salePersonId,
          'userType': 'TSM',
          'startDate': DateFormat('yyyy-MM-dd').format(start),
          'endDate': DateFormat('yyyy-MM-dd').format(end ?? start),
        }),
      );

      if (response.statusCode != 200) {
        if (mounted) {
          getFlushBar(context,
              title:
              'Failed to generate order form: ${_extractErrorMessage(response)}');
        }
        return;
      }

      final decoded = jsonDecode(response.body);
      final pdfUrl = decoded['data']?['pdfUrl'];

      if (!mounted) return;
      if (pdfUrl != null && pdfUrl.toString().isNotEmpty) {
        Navigator.pop(context); // close the filter sheet
        _openPdf(pdfUrl.toString(), title: 'Order Form');
      } else {
        getFlushBar(context, title: 'No orders found for the selected dates.');
      }
    } catch (e) {
      if (mounted) {
        getFlushBar(context, title: 'Something went wrong. Please try again.');
      }
    }
  }

  Future<void> _generateInvoices(DateTime start, DateTime? end) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final details = user.getSalesUserDetails();
    final salePersonId = details?.user?.id ?? '';
    final token = details?.token ?? '';

    if (salePersonId.isEmpty) {
      if (mounted) {
        getFlushBar(context,
            title:
            'Your session is missing required user info. Please log out and log back in.');
      }
      return;
    }

    try {
      final uri = Uri.parse('${BackendConfigs.apiUrl}order/report');
      final response = await http.post(
        uri,
        headers: _reportHeaders(token),
        body: jsonEncode({
          'salePerson': salePersonId,
          'startDate': DateFormat('yyyy-MM-dd').format(start),
          'endDate': DateFormat('yyyy-MM-dd').format(end ?? start),
        }),
      );

      if (response.statusCode != 200) {
        if (mounted) {
          getFlushBar(context,
              title:
              'Failed to generate invoices: ${_extractErrorMessage(response)}');
        }
        return;
      }

      final decoded = jsonDecode(response.body);
      final allUrls = (decoded['data'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();

      if (!mounted) return;

      if (allUrls.isEmpty) {
        getFlushBar(context, title: 'No invoices found for the selected dates.');
        return;
      }

      Navigator.pop(context); // close the filter sheet
      if (allUrls.length == 1) {
        _openPdf(allUrls.first, title: 'Invoice');
      } else {
        await _showInvoiceLinksSheet(allUrls);
      }
    } catch (e) {
      if (mounted) {
        getFlushBar(context, title: 'Something went wrong. Please try again.');
      }
    }
  }
}

// ── date-range bottom sheet (no entity filter) ───────────────────────────

void _showDateRangeSheet({
  required BuildContext context,
  required String buttonLabel,
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
            if (startDate == null || endDate == null) {
              getFlushBar(sheetContext,
                  title: 'Please select the required date(s)');
              return;
            }
            if (endDate!.isBefore(startDate!)) {
              getFlushBar(sheetContext,
                  title: 'End date cannot be before start date');
              return;
            }
            setSheetState(() => isGenerating = true);
            try {
              await onGenerate(startDate!, endDate);
            } finally {
              setSheetState(() => isGenerating = false);
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
              child: SingleChildScrollView(
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

                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: 'Start Date',
                            value: startDate,
                            onTap: () => pickDate(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            label: 'End Date',
                            value: endDate,
                            onTap: () => pickDate(false),
                          ),
                        ),
                      ],
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
            ),
          );
        },
      );
    },
  );
}

// ── date input box used in the report-generation bottom sheet ───────────
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateField({
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
