import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../configurations/frontend_configs.dart';
import '../../infrastructure/model/order.dart';
import '../../infrastructure/services/excel_report_builder.dart';
import '../../infrastructure/services/export_helper.dart';
import 'custom_text.dart';
import 'flush_bar.dart';

/// In-app table view for "Order Summary" — order/by-salesperson-date only
/// returns raw JSON (no backend-generated file the way Order Form / Overall
/// Invoices do), so this is the closest equivalent to [PdfViewerView] for
/// that report: shows the data directly in the app, with Share/Download
/// actions in the app bar that export the same rows as a real .xlsx.
class OrderSummaryTableView extends StatelessWidget {
  final List<OrderModel> orders;
  final DateTime startDate;
  final DateTime? endDate;

  const OrderSummaryTableView({
    super.key,
    required this.orders,
    required this.startDate,
    this.endDate,
  });

  String get _fileName =>
      'Order_Summary_${DateFormat('yyyy-MM-dd').format(startDate)}_to_'
      '${DateFormat('yyyy-MM-dd').format(endDate ?? startDate)}.xlsx';

  Future<void> _share(BuildContext context) async {
    try {
      final bytes = ExcelReportBuilder.buildOrdersSheet(orders);
      final file = await ExportHelper.saveBytes(bytes, _fileName);
      await ExportHelper.share(file);
    } catch (e) {
      if (context.mounted) {
        getFlushBar(context, title: 'Could not export the order summary.');
      }
    }
  }

  Future<void> _download(BuildContext context) async {
    try {
      final bytes = ExcelReportBuilder.buildOrdersSheet(orders);
      final file = await ExportHelper.saveBytes(bytes, _fileName);
      await ExportHelper.open(file);
    } catch (e) {
      if (context.mounted) {
        getFlushBar(context, title: 'Could not export the order summary.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = orders.fold<num>(0, (sum, o) => sum + (o.total ?? 0));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        title: CustomText(
          text: 'Order Summary',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _share(context),
          ),
          IconButton(
            tooltip: 'Download',
            icon: const Icon(Icons.download_outlined),
            onPressed: () => _download(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${orders.length} orders',
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
                width: 1180,
                child: Column(
                  children: [
                    _tableHeader(const [
                      _Col('Sr.', 40),
                      _Col('Date', 130),
                      _Col('TSM/Orderbooker', 140),
                      _Col('Distributor', 160),
                      _Col('Town', 90),
                      _Col('Shop Name', 160),
                      _Col('Type', 90),
                      _Col('Time', 90),
                      _Col('Amount', 110),
                      _Col('Items', 60),
                    ]),
                    Expanded(
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, i) {
                          final o = orders[i];
                          return _tableRow([
                            _cell('${i + 1}', 40),
                            _cell(
                              o.createdAt != null
                                  ? DateFormat('EEEE, MMMM d, yyyy')
                                      .format(o.createdAt!)
                                  : '-',
                              130,
                            ),
                            _cell(o.salesPerson?.name ?? '-', 140),
                            _cell(o.distributorName ?? '-', 160),
                            _cell(o.townName ?? '-', 90),
                            _cell(o.warehouseManager?.name ?? '-', 160),
                            _cell(o.warehouseManager?.customerType ?? '-', 90),
                            _cell(
                              o.createdAt != null
                                  ? DateFormat('HH:mm:ss').format(o.createdAt!)
                                  : '-',
                              90,
                            ),
                            _cell(
                              'PKR ${(o.total ?? 0).toStringAsFixed(2)}',
                              110,
                              bold: true,
                            ),
                            _cell('${o.items?.length ?? 0}', 60),
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
      ),
    );
  }
}

// ── table building blocks (mirrors _RecoveriesTable's style) ─────────────

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
