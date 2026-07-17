import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Copies a visit image into a persistent app directory (the same one
/// Hive already uses) instead of whatever temp/cache path the image
/// picker/editor returned it at. Only called when Offline Mode is on — a
/// queued order might not sync for hours, and OS-purgeable cache
/// directories (the picker's default) risk the file being cleared before
/// then. The original file is left in place; this only copies.
Future<String> persistVisitImageIfOffline(String sourcePath) async {
  final dir = await getApplicationDocumentsDirectory();
  final destDir = Directory('${dir.path}/offline_visits');
  if (!await destDir.exists()) {
    await destDir.create(recursive: true);
  }
  final destPath =
      '${destDir.path}/visit_${DateTime.now().millisecondsSinceEpoch}.jpg';
  await File(sourcePath).copy(destPath);
  return destPath;
}
