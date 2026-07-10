import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/add_recovery.dart';
import 'package:sm_networking/infrastructure/services/excel_report_builder.dart';
import 'package:sm_networking/infrastructure/services/export_helper.dart';
import 'package:sm_networking/infrastructure/services/order_booker_activity.dart';
import 'package:sm_networking/infrastructure/services/pdf_report_builder.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/elements/export_actions_sheet.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';

/// Shown for the `warehouseManager` role (reached from the "OrderBookers
/// Reporting" -> "Recovery" tile). Lists market recoveries across ALL order
/// bookers under this TSM by default; the "Orderbookers" dropdown at the top
/// lets the user narrow down to one specific order booker.
///
/// Both the "all" and "single" cases hit the same paginated endpoint —
/// `payment/tsm/{tsmId}/market-recovery` — just with or without
/// `orderBookerId`. Replaces the old flow of picking an order booker first
/// and then choosing "Market Recoveries" from an actions screen.
class OrderBookerRecoveriesView extends StatefulWidget {
  const OrderBookerRecoveriesView({super.key});

  @override
  State<OrderBookerRecoveriesView> createState() =>
      _OrderBookerRecoveriesViewState();
}

class _OrderBookerRecoveriesViewState
    extends State<OrderBookerRecoveriesView> {
  static const int _pageSize = 10;

  final ScrollController _scrollController = ScrollController();

  /// null = "All Orderbookers"
  String? _selectedOrderBookerId;

  /// Order bookers under this TSM, straight off UserProvider (same source
  /// used elsewhere in the app — already scoped to the logged-in TSM).
  List<dynamic> _orderBookers = [];

  final List<RecoveryModel> _items = [];
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
  num _totalAmount = 0;

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirstPage());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || _isInitialLoading) return;
    if (_page >= _totalPages) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadFirstPage() async {
    final details = context.read<UserProvider>().getSalesUserDetails();
    _orderBookers = details?.orderBookers ?? [];

    if (_orderBookers.isEmpty) {
      final tsmId = details?.user?.id ?? '';
      final token = details?.token ?? '';
      if (tsmId.isNotEmpty && token.isNotEmpty) {
        final result = await OrderBookerActivityRepositoryImp().getOrderBookersForTsm(
          tsmId: tsmId,
          token: token,
        );
        result.fold(
          (_) {},
          (orderBookers) {
            if (mounted) {
              setState(() {
                _orderBookers = orderBookers;
              });
            }
          },
        );
      }
    }

    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });
    await _fetch(page: 1, replace: true);
    if (mounted) setState(() => _isInitialLoading = false);
  }

  Future<void> _refresh() async {
    await _fetch(page: 1, replace: true);
  }

  Future<void> _loadNextPage() async {
    setState(() => _isLoadingMore = true);
    await _fetch(page: _page + 1, replace: false);
    if (mounted) setState(() => _isLoadingMore = false);
  }

  Future<void> _fetch({required int page, required bool replace}) async {
    final details = context.read<UserProvider>().getSalesUserDetails();
    final tsmId = details?.user?.id ?? '';
    final token = details?.token ?? '';

    if (tsmId.isEmpty || token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Session expired or not logged in. Please sign in again.';
        if (replace) _items.clear();
      });
      return;
    }

    final result = await OrderBookerActivityRepositoryImp().getAllMarketRecoveries(
      tsmId: tsmId,
      orderBookerId: _selectedOrderBookerId,
      page: page,
      limit: _pageSize,
      token: token,
    );

    if (!mounted) return;

    result.fold(
          (l) {
        setState(() {
          _errorMessage = l.error.toString();
          if (replace) _items.clear();
        });
      },
          (r) {
        setState(() {
          _errorMessage = null;
          if (replace) _items.clear();
          _items.addAll(r.data);
          _page = r.page;
          _totalPages = r.totalPages;
          _total = r.total;
          _totalAmount = r.totalAmount;
        });
      },
    );
  }

  void _onOrderBookerChanged(String? id) {
    if (id == _selectedOrderBookerId) return;
    setState(() {
      _selectedOrderBookerId = id;
      _items.clear();
      _page = 1;
      _totalPages = 1;
      _isInitialLoading = true;
    });
    _fetch(page: 1, replace: true).then((_) {
      if (mounted) setState(() => _isInitialLoading = false);
    });
  }

  // ── export (Excel / PDF) ─────────────────────────────────────────────
  //
  // Exports whatever the "Orderbookers" dropdown currently has selected —
  // one specific order booker, or all of them when it's "All Orderbookers".
  // Pulls every page fresh (not just what's been scrolled into [_items])
  // so the export is always complete regardless of scroll position.

  Future<List<RecoveryModel>> _fetchAllForExport() async {
    final details = context.read<UserProvider>().getSalesUserDetails();
    final tsmId = details?.user?.id ?? '';
    final token = details?.token ?? '';
    if (tsmId.isEmpty || token.isEmpty) return [];

    const exportPageSize = 200;
    final repo = OrderBookerActivityRepositoryImp();
    final all = <RecoveryModel>[];
    var page = 1;
    var totalPages = 1;
    do {
      final result = await repo.getAllMarketRecoveries(
        tsmId: tsmId,
        orderBookerId: _selectedOrderBookerId,
        page: page,
        limit: exportPageSize,
        token: token,
      );
      final ok = result.fold((_) => null, (r) => r);
      if (ok == null) break;
      all.addAll(ok.data);
      totalPages = ok.totalPages;
      page++;
    } while (page <= totalPages);
    return all;
  }

  /// File-name-safe label for whichever filter is active — the selected
  /// order booker's name, or "All_OrderBookers".
  String get _exportFileSuffix {
    if (_selectedOrderBookerId == null) return 'All_OrderBookers';
    final match = _orderBookers.firstWhere(
      (ob) => (ob.id ?? ob.salesId ?? '').toString() == _selectedOrderBookerId,
      orElse: () => null,
    );
    final name = (match?.name ?? 'OrderBooker').toString();
    return name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
  }

  Future<void> _exportRecoveries({required bool asExcel}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );

    final recoveries = await _fetchAllForExport();
    if (mounted) Navigator.of(context, rootNavigator: true).pop(); // close loading dialog

    if (recoveries.isEmpty) {
      if (mounted) getFlushBar(context, title: 'No recoveries to export.');
      return;
    }
    if (!mounted) return;

    final suffix = _exportFileSuffix;
    if (asExcel) {
      final bytes = ExcelReportBuilder.buildMarketRecoveriesSheet(recoveries);
      final file = await ExportHelper.saveBytes(
          bytes, 'Market_Recoveries_$suffix.xlsx');
      if (!mounted) return;
      await showExportActionsSheet(context,
          file: file, title: 'Market Recoveries');
    } else {
      final bytes = await PdfReportBuilder.buildMarketRecoveriesPdf(
          recoveries,
          title: 'Market Recoveries');
      final file = await ExportHelper.saveBytes(
          bytes, 'Market_Recoveries_$suffix.pdf');
      if (!mounted) return;
      await showExportActionsSheet(context,
          file: file, title: 'Market Recoveries');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(
        context,
        text: 'Recovery',
        showText: true,
        actions: [
          PopupMenuButton<bool>(
            tooltip: 'Export',
            icon: const Icon(Icons.ios_share, color: Colors.black),
            onSelected: (asExcel) => _exportRecoveries(asExcel: asExcel),
            itemBuilder: (context) => const [
              PopupMenuItem(value: true, child: Text('Export as Excel')),
              PopupMenuItem(value: false, child: Text('Export as PDF')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: _buildFilterDropdown(),
            ),
            if (!_isInitialLoading && (_total > 0 || _totalAmount > 0))
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: _buildSummaryRow(),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _isInitialLoading
                  ? const Center(child: ProcessingWidget())
                  : RefreshIndicator(
                onRefresh: _refresh,
                child: _buildList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: FrontendConfigs.kTextFieldColor,
        borderRadius: FrontendConfigs.kAppBorder,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: _selectedOrderBookerId,
          hint: const Text('Orderbookers'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Orderbookers'),
            ),
            ..._orderBookers.map((ob) {
              final id = (ob.id ?? ob.salesId ?? '').toString();
              final name = (ob.name ?? 'Unnamed order booker').toString();
              return DropdownMenuItem<String?>(
                value: id,
                child: Text(name, overflow: TextOverflow.ellipsis),
              );
            }),
          ],
          onChanged: _onOrderBookerChanged,
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$_total recoveries',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        Text(
          'PKR ${NumberFormat('#,##0').format(_totalAmount)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: FrontendConfigs.kPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_errorMessage != null && _items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_errorMessage!, textAlign: TextAlign.center),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: Text('No market recoveries yet')),
        ],
      );
    }

    final showMoreLoader = _page < _totalPages;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        width: 950,
        child: Column(
          children: [
            _tableHeader(const [
              _Col('S.No', 50),
              _Col('Date', 170),
              _Col('Distributor Name', 150),
              _Col('OrderBooker', 140),
              _Col('Town', 100),
              _Col('Payment', 120),
              _Col('Zone', 110),
              _Col('', 40),
            ]),
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _items.length + (showMoreLoader ? 1 : 0),
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (context, i) {
                  if (i >= _items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final m = _items[i];
                  return _tableRow([
                    _cell('${i + 1}', 50),
                    _cell(_formatDate(m.date), 170),
                    _cell(m.distributionName.isNotEmpty ? m.distributionName : '-', 150),
                    _cell(m.orderBookerName.isNotEmpty ? m.orderBookerName : '-', 140),
                    _cell(m.townName.isNotEmpty ? m.townName : '-', 100),
                    _cell(
                      'PKR ${NumberFormat('#,##0').format(m.amount)}',
                      120,
                      bold: true,
                    ),
                    _cell(m.zoneName.isNotEmpty ? m.zoneName : '-', 110),
                    SizedBox(
                      width: 40,
                      child: InkWell(
                        onTap: () => _showRecoveryDetails(context, m),
                        child: Icon(Icons.remove_red_eye_outlined,
                            size: 20, color: FrontendConfigs.kPrimaryColor),
                      ),
                    ),
                  ]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── recovery details dialog (behind the eye icon) ─────────────────────────

void _showRecoveryDetails(BuildContext context, RecoveryModel m) {
  final rows = <MapEntry<String, String>>[
    MapEntry('Date', _formatDate(m.date)),
    MapEntry('Distributor', m.distributionName),
    MapEntry('OrderBooker', m.orderBookerName),
    MapEntry('Zone', m.zoneName),
    MapEntry('Town', m.townName),
    MapEntry('Amount', 'PKR ${NumberFormat('#,##0').format(m.amount)}'),
    MapEntry('Payment Mode', m.paymentMode),
    MapEntry('Bank', m.bankName),
    if (m.branchCode.isNotEmpty) MapEntry('Branch Code', m.branchCode),
    if (m.beneficiaryAccountName.isNotEmpty)
      MapEntry('Beneficiary Name', m.beneficiaryAccountName),
    if (m.beneficiaryAccountNumber.isNotEmpty)
      MapEntry('Beneficiary Account', m.beneficiaryAccountNumber),
  ].where((e) => e.value.trim().isNotEmpty).toList();

  showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: FrontendConfigs.kAppBorder),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recovery Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (m.receiptPic != null && m.receiptPic!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  m.receiptPic!,
                  height: 140,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 12),
            ],
            ...rows.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          e.key,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(e.value, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    ),
  );
}

// ── shared table building blocks ─────────────────────────────────────────

class _Col {
  final String label;
  final double width;

  const _Col(this.label, this.width);
}

Widget _tableHeader(List<_Col> cols) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1.5)),
    ),
    child: Row(
      children: cols
          .map((c) => SizedBox(
                width: c.width,
                child: Text(
                  c.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ))
          .toList(),
    ),
  );
}

Widget _tableRow(List<Widget> cells) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: cells),
  );
}

Widget _cell(String text, double width, {bool bold = false}) {
  return SizedBox(
    width: width,
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      ),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    ),
  );
}

String _formatDate(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '-';
  try {
    return DateFormat('EEEE, MMMM d, yyyy').format(DateTime.parse(isoDate));
  } catch (_) {
    return isoDate;
  }
}
