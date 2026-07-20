import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Copies a recovery receipt image into a persistent app directory (the
/// same one visit images and Hive already use) instead of the temp/cache
/// path the image editor returns it at. Only called when Offline Mode is
/// on — a queued recovery might not sync for hours, and OS-purgeable cache
/// directories risk the file being cleared before then. The original file
/// is left in place; this only copies. Mirrors
/// offline_visit_image_store.dart's persistVisitImageIfOffline.
Future<String> persistRecoveryImageIfOffline(String sourcePath) async {
  final dir = await getApplicationDocumentsDirectory();
  final destDir = Directory('${dir.path}/offline_recoveries');
  if (!await destDir.exists()) {
    await destDir.create(recursive: true);
  }
  final destPath =
      '${destDir.path}/recovery_${DateTime.now().millisecondsSinceEpoch}.jpg';
  await File(sourcePath).copy(destPath);
  return destPath;
}
