import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../model/add_recovery.dart';

/// Builds a real .pdf file client-side for My Recoveries — there's no
/// backend endpoint returning a ready-made PDF for this report (unlike
/// Order Form / Overall Invoices, which already come from the server).
class PdfReportBuilder {
  static Future<Uint8List> buildRecoveriesPdf(
    List<RecoveryModel> recoveries, {
    String title = 'My Recoveries',
  }) async {
    final doc = pw.Document();
    final totalAmount =
        recoveries.fold<double>(0, (sum, m) => sum + m.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(title,
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(
            '${recoveries.length} recoveries — total PKR ${NumberFormat('#,##0').format(totalAmount)}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const [
              'S.No',
              'Date',
              'Distributor Name',
              'Town',
              'Payment (PKR)',
              'TSM',
              'Zone',
            ],
            data: [
              for (var i = 0; i < recoveries.length; i++)
                [
                  '${i + 1}',
                  _formatDate(recoveries[i].date),
                  recoveries[i].distributionName.isNotEmpty
                      ? recoveries[i].distributionName
                      : '-',
                  recoveries[i].townName.isNotEmpty
                      ? recoveries[i].townName
                      : '-',
                  NumberFormat('#,##0').format(recoveries[i].amount),
                  recoveries[i].tsmName.isNotEmpty ? recoveries[i].tsmName : '-',
                  recoveries[i].zoneName.isNotEmpty
                      ? recoveries[i].zoneName
                      : '-',
                ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: const {0: pw.Alignment.center, 4: pw.Alignment.centerRight},
          ),
        ],
      ),
    );

    return doc.save();
  }

  /// Market recoveries (Orderbookers Reporting → Recovery) — same as
  /// [buildRecoveriesPdf] but with an OrderBooker column, since this report
  /// can span all order bookers under a TSM, not just one.
  static Future<Uint8List> buildMarketRecoveriesPdf(
    List<RecoveryModel> recoveries, {
    String title = 'Market Recoveries',
  }) async {
    final doc = pw.Document();
    final totalAmount =
        recoveries.fold<double>(0, (sum, m) => sum + m.amount);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(title,
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(
            '${recoveries.length} recoveries — total PKR ${NumberFormat('#,##0').format(totalAmount)}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: const [
              'S.No',
              'Date',
              'Distributor Name',
              'OrderBooker',
              'Town',
              'Payment (PKR)',
              'Zone',
            ],
            data: [
              for (var i = 0; i < recoveries.length; i++)
                [
                  '${i + 1}',
                  _formatDate(recoveries[i].date),
                  recoveries[i].distributionName.isNotEmpty
                      ? recoveries[i].distributionName
                      : '-',
                  recoveries[i].orderBookerName.isNotEmpty
                      ? recoveries[i].orderBookerName
                      : '-',
                  recoveries[i].townName.isNotEmpty
                      ? recoveries[i].townName
                      : '-',
                  NumberFormat('#,##0').format(recoveries[i].amount),
                  recoveries[i].zoneName.isNotEmpty
                      ? recoveries[i].zoneName
                      : '-',
                ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: const {0: pw.Alignment.center, 5: pw.Alignment.centerRight},
          ),
        ],
      ),
    );

    return doc.save();
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
