import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Confirm dialog used across the app (logout, cancel order, delete draft,
/// location updates, ...). [navigation] is awaited: both buttons disable and
/// the confirm button shows a small spinner while it's in flight, so a
/// caller whose confirm action does real async work (network calls, GPS,
/// etc.) before popping the dialog can't be double-tapped into firing
/// twice — that gap is what let logout race the session-expiry handler.
///
/// Most callers pop the dialog themselves as the first or last step inside
/// [navigation]; this only adds visual feedback for whatever gap exists
/// before that happens; it doesn't pop anything on its own.
Future<void> showNavigationDialog(
  BuildContext context, {
  required String message,
  required String buttonText,
  required Future<void> Function() navigation,
  required String secondButtonText,
  required bool showSecondButton,
}) async {
  await showDialog(
    barrierDismissible: false,
    context: context,
    builder: (dialogContext) {
      bool isProcessing = false;
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return CupertinoAlertDialog(
            title: Text(
              "Message",
              style: TextStyle(color: Colors.green[900]),
            ),
            content: Text(message),
            actions: [
              if (showSecondButton == true)
                TextButton(
                  onPressed: isProcessing
                      ? null
                      : () => Navigator.pop(context),
                  child: Text(secondButtonText),
                ),
              TextButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        setDialogState(() => isProcessing = true);
                        await navigation();
                      },
                child: isProcessing
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(buttonText),
              ),
            ],
          );
        },
      );
    },
  );
}
