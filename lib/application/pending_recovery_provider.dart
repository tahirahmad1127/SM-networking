// lib/application/pending_recovery_provider.dart
import 'dart:io';

import 'package:flutter/material.dart';

import '../infrastructure/model/pending_recovery_order.dart';
import '../infrastructure/services/auth_token_helper.dart';
import '../infrastructure/services/pending_recovery.dart';
import '../infrastructure/services/retailer.dart';
import 'pending_sync_provider.dart';

/// Tracks "Add Recovery" payments queued while offline, and drives the
/// sync-one / sync-all / delete actions from the Pending Sync screen's
/// Recoveries tab. Mirrors PendingSyncProvider's shape exactly, but for
/// recoveries — kept as a separate provider since AddRecoveryModel has a
/// completely different payload from CreateOrderModel.
class PendingRecoveryProvider extends ChangeNotifier {
  List<PendingRecoveryOrder> _orders = [];
  final Set<String> _syncingIds = {};
  bool _isSyncingAll = false;

  List<PendingRecoveryOrder> get orders => List.unmodifiable(_orders);
  int get count => _orders.length;
  bool isSyncing(String localId) => _syncingIds.contains(localId);
  bool get isSyncingAll => _isSyncingAll;

  Future<void> load() async {
    _orders = await PendingRecoveryService.getAll();
    notifyListeners();
  }

  /// Syncs a single queued recovery. Returns true on success.
  Future<bool> syncOne(String localId) async {
    final order = _orders.firstWhere(
      (o) => o.localId == localId,
      orElse: () => throw StateError('Recovery not found: $localId'),
    );

    _syncingIds.add(localId);
    notifyListeners();

    bool success = false;
    try {
      final token = await getAuthToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      final result =
          await RetailerRepositoryImp().addRecovery(order.model, token);
      result.fold((_) => success = false, (_) => success = true);

      if (success) {
        final picPath = order.model.receiptPic;
        if (picPath != null && picPath.isNotEmpty) {
          try {
            await File(picPath).delete();
          } catch (_) {
            // Best-effort cleanup — a leftover file here doesn't block
            // anything, so a failed delete isn't worth surfacing.
          }
        }
        await PendingRecoveryService.remove(localId);
        _orders.removeWhere((o) => o.localId == localId);
      }
    } finally {
      _syncingIds.remove(localId);
      notifyListeners();
    }
    return success;
  }

  /// Syncs every pending recovery, one at a time. Recoveries that fail stay
  /// in the queue for a later retry.
  Future<SyncAllResult> syncAll() async {
    _isSyncingAll = true;
    notifyListeners();

    int succeeded = 0;
    int failed = 0;

    final snapshot = List<PendingRecoveryOrder>.from(_orders);
    for (final order in snapshot) {
      final ok = await syncOne(order.localId);
      if (ok) {
        succeeded++;
      } else {
        failed++;
      }
    }

    _isSyncingAll = false;
    notifyListeners();
    return SyncAllResult(succeeded: succeeded, failed: failed);
  }

  Future<void> deleteOne(String localId) async {
    await PendingRecoveryService.remove(localId);
    _orders.removeWhere((o) => o.localId == localId);
    notifyListeners();
  }
}
