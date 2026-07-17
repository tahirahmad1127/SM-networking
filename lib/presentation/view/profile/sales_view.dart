import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/back_end_configs.dart';
import 'package:sm_networking/infrastructure/model/order.dart';
import 'package:sm_networking/infrastructure/services/order_booker_activity.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:sm_networking/presentation/elements/order_summary_table_view.dart';
import 'package:sm_networking/presentation/view/profile/layout/widgets/profile_card.dart';

import '../../../../configurations/frontend_configs.dart';
import '../../elements/custom_text.dart';
import '../../elements/pdf_viewer_view.dart';

/// "Sales" screen, pushed from a list tile on the Profile page (same pattern
/// as "My Recoveries" / "Orderbookers"). Lists the three report actions —
/// Order Summary, Order Form, Overall Invoices — as their own list tiles.
///
/// Each report now requires the user to pick a filter type (Distributor or
/// Order Booker) and then a specific entity of that type — both drawn from
/// the TSM's own `distributors` / `orderBookers` lists already present on
/// [UserProvider], so no new API call is needed to populate the dropdowns.
/// Generated PDFs open in-app via [PdfViewerView].
class SalesView extends StatefulWidget {
  const SalesView({super.key});

  @override
  State<SalesView> createState() => _SalesViewState();
}

/// Internal key for which kind of entity the user is filtering by.
enum _FilterType { distributor, orderBooker }

/// A single item in the second ("specific entity") dropdown.
class _FilterEntity {
  final String id;
  final String name;

  const _FilterEntity({required this.id, required this.name});
}

class _SalesViewState extends State<SalesView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: CustomText(
          text: 'Sales',
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

                // ── Generate Order Summary ───────────────────────────────
                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () => _showReportFilterSheet(
                    context: context,
                    buttonLabel: 'Generate Order Summary',
                    useDateRange: true,
                    onGenerate: _generateOrderSummary,
                  ),
                  child: ProfileCard(lebal: 'Generate Order Summary'),
                ),

                const SizedBox(height: 12),

                // ── Generate Order Form ──────────────────────────────────
                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () => _showReportFilterSheet(
                    context: context,
                    buttonLabel: 'Generate Order Form',
                    useDateRange: true,
                    onGenerate: _generateOrderForm,
                  ),
                  child: ProfileCard(lebal: 'Generate Order Form'),
                ),

                const SizedBox(height: 12),

                // ── Generate Overall Invoices ────────────────────────────
                InkWell(
                  borderRadius: FrontendConfigs.kAppBorder,
                  onTap: () => _showReportFilterSheet(
                    context: context,
                    buttonLabel: 'Generate Overall Invoices',
                    useDateRange: true,
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

  String _mapUserTypeForReports(String role) {
    final r = role.toLowerCase();
    if (r.contains('order') || r.contains('booker')) return 'Order Booker';
    return 'TSM';
  }

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

  /// order/by-salesperson-date's exact response shape isn't nailed down
  /// (raw JSON, not a file) — accepts a bare list, or a map wrapping the
  /// list under `data`/`orders`/`result`, matching how the rest of the app
  /// defensively parses similar endpoints (see OrderBookerActivityRepository).
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

  // ── report generation ────────────────────────────────────────────────
  //
  // Each generator now takes [filterType] + [entityId] in addition to the
  // dates, and adds exactly one of `distributorId` / `orderBookerId` to the
  // request body, per the backend's contract:
  //   { salePerson, startDate, endDate, distributorId? , orderBookerId? }

  Map<String, dynamic> _filterField(_FilterType filterType, String entityId) {
    return filterType == _FilterType.distributor
        ? {'distributorId': entityId}
        : {'orderBookerId': entityId};
  }

  /// /api/order/by-salesperson-date returns the raw order JSON for the
  /// range (not a pdfUrl like the other two reports), so this builds a real
  /// .xlsx file client-side from that data instead of opening a PDF.
  Future<void> _generateOrderSummary(
      DateTime start,
      DateTime? end,
      _FilterType filterType,
      String entityId,
      ) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final details = user.getSalesUserDetails();
    final salePersonId = details?.user?.id ?? '';
    final token = details?.token ?? '';
    final userType = _mapUserTypeForReports(details?.role ?? '');

    if (salePersonId.isEmpty) {
      if (mounted) {
        getFlushBar(context,
            title:
            'Your session is missing required user info. Please log out and log back in.');
      }
      return;
    }

    final uri = Uri.parse('${BackendConfigs.apiUrl}order/by-salesperson-date');
    final body = {
      'salePerson': salePersonId,
      'userType': userType,
      'startDate': DateFormat('yyyy-MM-dd').format(start),
      'endDate': DateFormat('yyyy-MM-dd').format(end ?? start),
      ..._filterField(filterType, entityId),
    };
    final executionTime = DateTime.now();
    log("Generate order summary -> POST $uri | body: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        uri,
        headers: _reportHeaders(token),
        body: jsonEncode(body),
      );
      log("Generate order summary <- status: ${response.statusCode} | "
          "${DateTime.now().difference(executionTime).inMilliseconds}ms | "
          "body: ${response.body}");

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
      log("Generate order summary threw: $e");
      if (mounted) {
        getFlushBar(context, title: 'Something went wrong. Please try again.');
      }
    }
  }

  Future<void> _generateOrderForm(
      DateTime start,
      DateTime? end,
      _FilterType filterType,
      String entityId,
      ) async {
    final user = Provider.of<UserProvider>(context, listen: false);
    final details = user.getSalesUserDetails();
    final salePersonId = details?.user?.id ?? '';
    final token = details?.token ?? '';
    final userType = _mapUserTypeForReports(details?.role ?? '');

    if (salePersonId.isEmpty) {
      if (mounted) {
        getFlushBar(context,
            title:
            'Your session is missing required user info. Please log out and log back in.');
      }
      return;
    }

    final uri = Uri.parse('${BackendConfigs.apiUrl}order/load-form');
    final body = {
      'salePerson': salePersonId,
      'userType': userType,
      'startDate': DateFormat('yyyy-MM-dd').format(start),
      'endDate': DateFormat('yyyy-MM-dd').format(end ?? start),
      ..._filterField(filterType, entityId),
    };
    final executionTime = DateTime.now();
    log("Generate order form -> POST $uri | body: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        uri,
        headers: _reportHeaders(token),
        body: jsonEncode(body),
      );
      log("Generate order form <- status: ${response.statusCode} | "
          "${DateTime.now().difference(executionTime).inMilliseconds}ms | "
          "body: ${response.body}");

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
      log("Generate order form threw: $e");
      if (mounted) {
        getFlushBar(context, title: 'Something went wrong. Please try again.');
      }
    }
  }

  /// /api/order/report now accepts a startDate/endDate range directly, so
  /// this is a single call instead of the previous per-day loop.
  Future<void> _generateInvoices(
      DateTime start,
      DateTime? end,
      _FilterType filterType,
      String entityId,
      ) async {
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

    final uri = Uri.parse('${BackendConfigs.apiUrl}order/report');
    final body = {
      'salePerson': salePersonId,
      'startDate': DateFormat('yyyy-MM-dd').format(start),
      'endDate': DateFormat('yyyy-MM-dd').format(end ?? start),
      ..._filterField(filterType, entityId),
    };
    final executionTime = DateTime.now();
    log("Generate invoices -> POST $uri | body: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        uri,
        headers: _reportHeaders(token),
        body: jsonEncode(body),
      );
      log("Generate invoices <- status: ${response.statusCode} | "
          "${DateTime.now().difference(executionTime).inMilliseconds}ms | "
          "body: ${response.body}");

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
      log("Generate invoices threw: $e");
      if (mounted) {
        getFlushBar(context, title: 'Something went wrong. Please try again.');
      }
    }
  }
}

// ── entities available for the second dropdown ───────────────────────────

/// Reads the TSM's own distributors/order-bookers straight off
/// [UserProvider] — both lists are already scoped to the logged-in TSM from
/// the login response, so no extra API call is needed.
List<_FilterEntity> _entitiesForFilterType(
    BuildContext context,
    _FilterType filterType,
    ) {
  final details =
  Provider.of<UserProvider>(context, listen: false).getSalesUserDetails();

  if (filterType == _FilterType.distributor) {
    final distributors = details?.distributors ?? [];
    return distributors
        .map((d) => _FilterEntity(
      id: (d.id ?? d.salesId ?? '').toString(),
      name: (d.distributionName?.isNotEmpty == true)
          ? d.distributionName!
          : (d.name ?? 'Unnamed distributor'),
    ))
        .where((e) => e.id.isNotEmpty)
        .toList();
  }

  final orderBookers = details?.orderBookers ?? [];
  return orderBookers
      .map((ob) => _FilterEntity(
    // ASSUMPTION: falls back to `salesId` the same way the
    // distributor list does, since I haven't seen an explicit `id`
    // field on the order-booker object — please confirm with your
    // backend dev that this is the value `orderBookerId` expects.
    id: (ob.id ?? ob.salesId ?? '').toString(),
    name: ob.name ?? 'Unnamed order booker',
  ))
      .where((e) => e.id.isNotEmpty)
      .toList();
}

/// Falls back to `GET warehouse-manager/:tsmId/order-bookers` when
/// [UserProvider]'s in-memory `orderBookers` list is empty — mirrors the
/// same fallback already used by the Attendance & Tracking / Recovery
/// screens, which is why those show all order bookers while this dropdown
/// was showing "None found" (login response doesn't always include
/// `orderBookers`, unlike `distributors`).
Future<List<_FilterEntity>> _fetchOrderBookersFromApi(BuildContext context) async {
  final details =
  Provider.of<UserProvider>(context, listen: false).getSalesUserDetails();
  final tsmId = details?.user?.id ?? '';
  final token = details?.token ?? '';
  if (tsmId.isEmpty || token.isEmpty) return [];

  final result = await OrderBookerActivityRepositoryImp().getOrderBookersForTsm(
    tsmId: tsmId,
    token: token,
  );

  return result.fold(
    (_) => <_FilterEntity>[],
        (orderBookers) => orderBookers
        .map((ob) => _FilterEntity(
      id: (ob.id ?? ob.salesId ?? '').toString(),
      name: ob.name ?? 'Unnamed order booker',
    ))
        .where((e) => e.id.isNotEmpty)
        .toList(),
  );
}

// ── filter + date-picker bottom sheet ────────────────────────────────────

void _showReportFilterSheet({
  required BuildContext context,
  required String buttonLabel,
  required bool useDateRange,
  required Future<void> Function(
      DateTime start,
      DateTime? end,
      _FilterType filterType,
      String entityId,
      ) onGenerate,
}) {
  _FilterType? filterType;
  List<_FilterEntity> entities = [];
  _FilterEntity? selectedEntity;
  DateTime? startDate;
  DateTime? endDate;
  bool isGenerating = false;
  bool isLoadingEntities = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          Future<void> onFilterTypeChanged(_FilterType? type) async {
            if (type == null) return;
            setSheetState(() {
              filterType = type;
              // Reset the specific-entity selection whenever the type changes.
              selectedEntity = null;
              entities = _entitiesForFilterType(context, type);
            });

            // Distributors are always present in the in-memory list. Order
            // bookers sometimes aren't (see _fetchOrderBookersFromApi) — hit
            // the live endpoint in that case instead of showing "None found".
            if (type == _FilterType.orderBooker && entities.isEmpty) {
              setSheetState(() => isLoadingEntities = true);
              final fetched = await _fetchOrderBookersFromApi(context);
              if (!context.mounted) return;
              setSheetState(() {
                isLoadingEntities = false;
                entities = fetched;
              });
            }
          }

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
            if (filterType == null || selectedEntity == null) {
              getFlushBar(sheetContext,
                  title: 'Please select a distributor or order booker');
              return;
            }
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
              await onGenerate(
                startDate!,
                useDateRange ? endDate : null,
                filterType!,
                selectedEntity!.id,
              );
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

                    // ── Filter type dropdown ─────────────────────────────
                    CustomText(
                      text: 'Filter By',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: FrontendConfigs.kTextFieldColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<_FilterType>(
                          isExpanded: true,
                          hint: const Text('Select Distributor or Order Booker'),
                          value: filterType,
                          items: const [
                            DropdownMenuItem(
                              value: _FilterType.distributor,
                              child: Text('Distributor'),
                            ),
                            DropdownMenuItem(
                              value: _FilterType.orderBooker,
                              child: Text('Order Booker'),
                            ),
                          ],
                          onChanged: onFilterTypeChanged,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Specific entity dropdown ─────────────────────────
                    if (filterType != null) ...[
                      CustomText(
                        text: filterType == _FilterType.distributor
                            ? 'Select Distributor'
                            : 'Select Order Booker',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: FrontendConfigs.kTextFieldColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isLoadingEntities
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 10),
                                    Text('Loading…'),
                                  ],
                                ),
                              )
                            : DropdownButtonHideUnderline(
                                child: DropdownButton<_FilterEntity>(
                                  isExpanded: true,
                                  hint: Text(entities.isEmpty
                                      ? 'None found'
                                      : 'Select an option'),
                                  value: selectedEntity,
                                  items: entities
                                      .map((e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e.name,
                                        overflow: TextOverflow.ellipsis),
                                  ))
                                      .toList(),
                                  onChanged: entities.isEmpty
                                      ? null
                                      : (e) => setSheetState(
                                          () => selectedEntity = e),
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Dates ─────────────────────────────────────────────
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
            ),
          );
        },
      );
    },
  );
}

// ── date input box used in the report-generation bottom sheet ───────────
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