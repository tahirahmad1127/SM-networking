import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Shared save/share/open plumbing for every generated report file
/// (Excel or PDF), so Order Summary, My Recoveries, etc. all behave the
/// same way once a file is generated.
class ExportHelper {
  /// Writes [bytes] to a device-accessible folder under [fileName] and
  /// returns the resulting [File].
  ///
  /// Android: the app's external files dir (visible to file managers under
  /// `Android/data/{package}/files` — no storage permission needed).
  /// iOS: the app's documents dir (visible in the Files app under
  /// "On My iPhone/iPad" once file sharing is enabled).
  static Future<File> saveBytes(Uint8List bytes, String fileName) async {
    final dir = Platform.isAndroid
        ? (await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory())
        : await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    return file.writeAsBytes(bytes, flush: true);
  }

  /// Opens the OS share sheet (save to Files/Drive, send via WhatsApp/email,
  /// etc.) for the given file.
  static Future<void> share(File file, {String? subject}) {
    return SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: subject),
    );
  }

  /// Hands the file to whatever app the OS associates with its type —
  /// Excel/Sheets for .xlsx, a PDF viewer or browser for .pdf. This is the
  /// "opens in browser" fallback for file types Flutter can't render itself.
  static Future<void> open(File file) {
    return OpenFilex.open(file.path);
  }
}
