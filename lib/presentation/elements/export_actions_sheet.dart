import 'dart:io';

import 'package:flutter/material.dart';

import '../../configurations/frontend_configs.dart';
import '../../infrastructure/services/export_helper.dart';
import 'custom_text.dart';

/// Bottom sheet shown after a report file (.xlsx or .pdf) has been
/// generated and saved to the device. Flutter can't render a spreadsheet
/// in-app, so instead of a preview this offers the two actions that
/// actually matter: Share (native share sheet — WhatsApp, email, Drive,
/// "Save to Files", ...) and Download (opens the already-saved file with
/// whatever app/browser the OS associates with its type).
Future<void> showExportActionsSheet(
  BuildContext context, {
  required File file,
  required String title,
}) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            CustomText(
              text: title,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            const SizedBox(height: 4),
            CustomText(
              text: file.path.split(Platform.pathSeparator).last,
              fontSize: 12,
              color: Colors.grey.shade600,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      ExportHelper.share(file);
                    },
                    icon: Icon(Icons.share_outlined,
                        color: FrontendConfigs.kPrimaryColor),
                    label: Text(
                      'Share',
                      style: TextStyle(
                        color: FrontendConfigs.kPrimaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: FrontendConfigs.kPrimaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      ExportHelper.open(file);
                    },
                    icon: const Icon(Icons.download_outlined, color: Colors.white),
                    label: const Text(
                      'Download',
                      style:
                          TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FrontendConfigs.kPrimaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
