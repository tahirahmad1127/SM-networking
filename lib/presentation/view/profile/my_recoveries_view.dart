import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sm_networking/application/user_provider.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/infrastructure/model/add_recovery.dart';
import 'package:sm_networking/infrastructure/model/error.dart';
import 'package:sm_networking/infrastructure/services/excel_report_builder.dart';
import 'package:sm_networking/infrastructure/services/export_helper.dart';
import 'package:sm_networking/infrastructure/services/pdf_report_builder.dart';
import 'package:sm_networking/infrastructure/services/retailer.dart';
import 'package:sm_networking/presentation/elements/custom_appbar.dart';
import 'package:sm_networking/presentation/elements/export_actions_sheet.dart';
import 'package:sm_networking/presentation/elements/flush_bar.dart';
import 'package:sm_networking/presentation/elements/processing_widget.dart';

class MyRecoveriesView extends StatefulWidget {
  const MyRecoveriesView({super.key});

  @override
  State<MyRecoveriesView> createState() => _MyRecoveriesViewState();
}

class _MyRecoveriesViewState extends State<MyRecoveriesView> {
  late Future<Either<GlobalErrorModel, RecoveryListingModel>> _future;
  bool _futureInited = false;

  // Both roles ("warehouseManager" and "orderBooker") land on this same
  // screen — filtering is done client-side since `payment/get-my-payment`
  // doesn't accept a date range, it always returns the full history.
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  bool _matchesDateFilter(RecoveryModel m) {
    if (_startDate == null && _endDate == null) return true;
    final parsed = DateTime.tryParse(m.date ?? '');
    if (parsed == null) return false;
    final d = DateTime(parsed.year, parsed.month, parsed.day);
    if (_startDate != null &&
        d.isBefore(DateTime(_startDate!.year, _startDate!.month, _startDate!.day))) {
      return false;
    }
    if (_endDate != null &&
        d.isAfter(DateTime(_endDate!.year, _endDate!.month, _endDate!.day))) {
      return false;
    }
    return true;
  }

  // ── export (Excel / PDF) — respects whatever date filter is active ──────
  Future<void> _exportRecoveries({required bool asExcel}) async {
    final result = await _future;
    final recoveries = result.fold(
      (l) => <RecoveryModel>[],
      (r) => r.data.where(_matchesDateFilter).toList(),
    );

    if (recoveries.isEmpty) {
      if (mounted) {
        getFlushBar(context, title: 'No recoveries to export.');
      }
      return;
    }

    final rangeSuffix = _startDate == null && _endDate == null
        ? 'All'
        : '${_startDate != null ? DateFormat('yyyy-MM-dd').format(_startDate!) : 'Start'}_to_'
            '${_endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : 'Now'}';

    if (!mounted) return;

    if (asExcel) {
      final bytes = ExcelReportBuilder.buildRecoveriesSheet(recoveries);
      final file =
          await ExportHelper.saveBytes(bytes, 'My_Recoveries_$rangeSuffix.xlsx');
      if (!mounted) return;
      await showExportActionsSheet(context, file: file, title: 'My Recoveries');
    } else {
      final bytes = await PdfReportBuilder.buildRecoveriesPdf(recoveries,
          title: 'My Recoveries');
      final file =
          await ExportHelper.saveBytes(bytes, 'My_Recoveries_$rangeSuffix.pdf');
      if (!mounted) return;
      await showExportActionsSheet(context, file: file, title: 'My Recoveries');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futureInited) return;
    _futureInited = true;
    final token =
        context.read<UserProvider>().getSalesUserDetails()?.token ?? '';
    _future = token.isEmpty
        ? Future.value(
            Left(
              GlobalErrorModel(
                error:
                    'Session expired or not logged in. Please sign in again.',
              ),
            ),
          )
        : RetailerRepositoryImp().getMyPayments(token);
  }

  Future<void> _reload() async {
    final token =
        context.read<UserProvider>().getSalesUserDetails()?.token ?? '';
    setState(() {
      _future = token.isEmpty
          ? Future.value(
              Left(
                GlobalErrorModel(
                  error:
                      'Session expired or not logged in. Please sign in again.',
                ),
              ),
            )
          : RetailerRepositoryImp().getMyPayments(token);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final hasDateFilter = _startDate != null || _endDate != null;

    return Scaffold(
      appBar: customAppBar(
        context,
        text: 'My Recoveries',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Start Date',
                    value: _startDate,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'End Date',
                    value: _endDate,
                    onTap: () => _pickDate(false),
                  ),
                ),
                if (hasDateFilter)
                  IconButton(
                    tooltip: 'Clear date filter',
                    icon: const Icon(Icons.close),
                    onPressed: _clearDateFilter,
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              child:
                  FutureBuilder<Either<GlobalErrorModel, RecoveryListingModel>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: ProcessingWidget());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(snapshot.error.toString(),
                              textAlign: TextAlign.center),
                        ),
                      ],
                    );
                  }
                  final result = snapshot.data;
                  if (result == null) {
                    return const SizedBox.shrink();
                  }
                  return result.fold(
                    (l) => ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(l.error.toString(),
                              textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                    (r) {
                      if (r.data.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('No recoveries yet')),
                          ],
                        );
                      }
                      final filtered =
                          r.data.where(_matchesDateFilter).toList();
                      if (filtered.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                                child: Text(
                                    'No recoveries in the selected date range')),
                          ],
                        );
                      }
                      return _RecoveriesTable(data: filtered);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── table layout (mirrors the web portal's recoveries table) ─────────────

class _RecoveriesTable extends StatelessWidget {
  final List<RecoveryModel> data;

  const _RecoveriesTable({required this.data});

  @override
  Widget build(BuildContext context) {
    // Computed from the loaded rows rather than listing.total/totalAmount —
    // those aggregate fields come from the market-recovery endpoint's
    // response shape and aren't confirmed present on this "my payments"
    // endpoint, so trusting them could silently show "0 recoveries" even
    // though the table below has rows.
    final totalCount = data.length;
    final totalAmount = data.fold<num>(0, (sum, m) => sum + m.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalCount recoveries',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              Text(
                '${NumberFormat('#,##0').format(totalAmount)} PKR',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FrontendConfigs.kPrimaryColor,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              width: 900,
              child: Column(
                children: [
                  _tableHeader(const [
                    _Col('S.No', 50),
                    _Col('Date', 170),
                    _Col('Distributor Name', 160),
                    _Col('Town', 100),
                    _Col('Payment', 120),
                    _Col('TSM', 130),
                    _Col('Zone', 110),
                    _Col('', 40),
                  ]),
                  Expanded(
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: data.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (context, i) {
                        final m = data[i];
                        return _tableRow([
                          _cell('${i + 1}', 50),
                          _cell(_formatDate(m.date), 170),
                          _cell(m.distributionName.isNotEmpty ? m.distributionName : '-', 160),
                          _cell(m.townName.isNotEmpty ? m.townName : '-', 100),
                          _cell(
                            'PKR ${NumberFormat('#,##0').format(m.amount)}',
                            120,
                            bold: true,
                          ),
                          _cell(m.tsmName.isNotEmpty ? m.tsmName : '-', 130),
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
          ),
        ),
      ],
    );
  }
}

// ── recovery details dialog (behind the eye icon) ─────────────────────────

void _showRecoveryDetails(BuildContext context, RecoveryModel m) {
  final rows = <MapEntry<String, String>>[
    MapEntry('Date', _formatDate(m.date)),
    MapEntry('Distributor', m.distributionName),
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

// ── date input box (mirrors the Start Date / End Date fields used in the
// report-generation sheets on Sales / My Sales) ───────────────────────────
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
    final text =
        value == null ? 'mm/dd/yyyy' : DateFormat('MM/dd/yyyy').format(value!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
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
                    color: value == null ? Colors.grey.shade500 : Colors.black87,
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
