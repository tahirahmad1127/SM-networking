import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../model/add_recovery.dart';
import '../model/order.dart';

/// Builds real .xlsx files (client-side) for the reports that don't have a
/// backend-generated file to download — Order Summary and My Recoveries.
class ExcelReportBuilder {
  static Uint8List _finish(Excel workbook) {
    final bytes = workbook.save();
    if (bytes == null) {
      throw Exception('Failed to generate the Excel file.');
    }
    return Uint8List.fromList(bytes);
  }

  static void _writeHeaderRow(Sheet sheet, List<String> headers) {
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    final boldHeader = CellStyle(bold: true);
    for (var c = 0; c < headers.length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
          .cellStyle = boldHeader;
    }
  }

  /// Order Summary — one row per order.
  static Uint8List buildOrdersSheet(List<OrderModel> orders) {
    final workbook = Excel.createExcel();
    final sheet = workbook[workbook.getDefaultSheet()!];
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    _writeHeaderRow(sheet, const [
      'S.No',
      'Date',
      'Distributor',
      'Items',
      'Total (PKR)',
      'Payment Type',
      'Status',
    ]);

    for (var i = 0; i < orders.length; i++) {
      final o = orders[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(
            o.createdAt != null ? dateFormat.format(o.createdAt!) : '-'),
        TextCellValue(o.warehouseManager?.name ?? '-'),
        IntCellValue(o.items?.length ?? 0),
        DoubleCellValue((o.total ?? 0).toDouble()),
        TextCellValue(o.paymentType ?? '-'),
        TextCellValue(o.status ?? '-'),
      ]);
    }

    return _finish(workbook);
  }

  /// My Recoveries — mirrors the columns already shown in the in-app table
  /// (see _RecoveriesTable in my_recoveries_view.dart).
  static Uint8List buildRecoveriesSheet(List<RecoveryModel> recoveries) {
    final workbook = Excel.createExcel();
    final sheet = workbook[workbook.getDefaultSheet()!];

    _writeHeaderRow(sheet, const [
      'S.No',
      'Date',
      'Distributor Name',
      'Town',
      'Payment (PKR)',
      'TSM',
      'Zone',
    ]);

    for (var i = 0; i < recoveries.length; i++) {
      final m = recoveries[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(_formatDate(m.date)),
        TextCellValue(m.distributionName.isNotEmpty ? m.distributionName : '-'),
        TextCellValue(m.townName.isNotEmpty ? m.townName : '-'),
        DoubleCellValue(m.amount),
        TextCellValue(m.tsmName.isNotEmpty ? m.tsmName : '-'),
        TextCellValue(m.zoneName.isNotEmpty ? m.zoneName : '-'),
      ]);
    }

    return _finish(workbook);
  }

  /// Market recoveries (Orderbookers Reporting → Recovery) — mirrors
  /// orderbooker_recoveries_view.dart's in-app table columns, which include
  /// an OrderBooker column since this report can span all order bookers
  /// under a TSM, not just one.
  static Uint8List buildMarketRecoveriesSheet(List<RecoveryModel> recoveries) {
    final workbook = Excel.createExcel();
    final sheet = workbook[workbook.getDefaultSheet()!];

    _writeHeaderRow(sheet, const [
      'S.No',
      'Date',
      'Distributor Name',
      'OrderBooker',
      'Town',
      'Payment (PKR)',
      'Zone',
    ]);

    for (var i = 0; i < recoveries.length; i++) {
      final m = recoveries[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(_formatDate(m.date)),
        TextCellValue(m.distributionName.isNotEmpty ? m.distributionName : '-'),
        TextCellValue(m.orderBookerName.isNotEmpty ? m.orderBookerName : '-'),
        TextCellValue(m.townName.isNotEmpty ? m.townName : '-'),
        DoubleCellValue(m.amount),
        TextCellValue(m.zoneName.isNotEmpty ? m.zoneName : '-'),
      ]);
    }

    return _finish(workbook);
  }

  static String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }
}
