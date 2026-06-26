// lib/application/pending_sync_provider.dart
import 'package:flutter/material.dart';

import '../infrastructure/model/pending_sync_order.dart';
import '../infrastructure/services/order.dart';
import '../infrastructure/services/pending_sync.dart';
import '../injection_container.dart';

/// Simple result holder for [PendingSyncProvider.syncAll]. A plain class is
/// used instead of a Dart record so this compiles on older SDK constraints
/// that don't have the records language feature enabled.
class SyncAllResult {
  final int succeeded;
  final int failed;

  const SyncAllResult({required this.succeeded, required this.failed});
}

/// Tracks which local orders are still waiting to reach the backend, and
/// drives the sync-one / sync-all / delete actions from the Pending Sync
/// screen. Also exposes a simple count for the FAB badge.
class PendingSyncProvider extends ChangeNotifier {
  List<PendingSyncOrder> _orders = [];
  final Set<String> _syncingIds = {};
  bool _isSyncingAll = false;

  List<PendingSyncOrder> get orders => List.unmodifiable(_orders);
  int get count => _orders.length;
  bool isSyncing(String localId) => _syncingIds.contains(localId);
  bool get isSyncingAll => _isSyncingAll;

  Future<void> load() async {
    _orders = await PendingSyncService.getAll();
    notifyListeners();
  }

  /// Syncs a single order. Returns true on success.
  Future<bool> syncOne(String localId) async {
    final order = _orders.firstWhere(
          (o) => o.localId == localId,
      orElse: () => throw StateError('Order not found: $localId'),
    );

    _syncingIds.add(localId);
    notifyListeners();

    bool success = false;
    try {
      final result = await sl<OrderRepositoryImp>().createOrder(order.model);
      result.fold(
            (_) {
          success = false;
        },
            (_) {
          success = true;
        },
      );

      if (success) {
        await PendingSyncService.remove(localId);
        _orders.removeWhere((o) => o.localId == localId);
      }
    } finally {
      _syncingIds.remove(localId);
      notifyListeners();
    }
    return success;
  }

  /// Syncs every pending order, one at a time. Orders that fail stay in
  /// the queue for a later retry.
  Future<SyncAllResult> syncAll() async {
    _isSyncingAll = true;
    notifyListeners();

    int succeeded = 0;
    int failed = 0;

    // Iterate over a snapshot since syncOne mutates _orders as it goes.
    final snapshot = List<PendingSyncOrder>.from(_orders);
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
    await PendingSyncService.remove(localId);
    _orders.removeWhere((o) => o.localId == localId);
    notifyListeners();
  }
}