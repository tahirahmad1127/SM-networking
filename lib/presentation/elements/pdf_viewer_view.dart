import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

import 'custom_text.dart';

/// Full-screen in-app PDF viewer.
///
/// Downloads the PDF bytes from [pdfUrl] and renders them with the
/// `printing` package's [PdfPreview] widget, so the report opens inside the
/// app instead of handing off to the device's browser.
///
/// ASSUMPTION: this relies on the `printing` package (MIT licensed) being
/// added to pubspec.yaml — I don't have that file, so please add:
///   printing: ^5.13.3
/// (or the latest compatible version) under dependencies, then run
/// `flutter pub get`.
class PdfViewerView extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerView({
    super.key,
    required this.pdfUrl,
    this.title = 'Document',
  });

  @override
  State<PdfViewerView> createState() => _PdfViewerViewState();
}

class _PdfViewerViewState extends State<PdfViewerView> {
  late Future<Uint8List> _pdfBytesFuture;

  @override
  void initState() {
    super.initState();
    _pdfBytesFuture = _fetchPdfBytes();
  }

  Future<Uint8List> _fetchPdfBytes() async {
    final response = await http.get(Uri.parse(widget.pdfUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to download PDF (${response.statusCode})');
    }
    return response.bodyBytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        title: CustomText(
          text: widget.title,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfBytesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: CustomText(
                  text: 'Could not load the PDF. Please try again.',
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            );
          }
          return PdfPreview(
            build: (format) => snapshot.data!,
            allowSharing: true,
            allowPrinting: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
          );
        },
      ),
    );
  }
}