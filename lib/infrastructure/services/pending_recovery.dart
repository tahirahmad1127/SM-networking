// lib/infrastructure/services/pending_recovery.dart
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/pending_recovery_order.dart';

const String _kPendingRecoveryKey = 'pending_recovery_orders';

/// Local-only persistence for "Add Recovery" payments recorded while
/// offline. Parallel in spirit and API shape to PendingSyncService, but for
/// recoveries instead of orders — kept as a separate SharedPreferences key
/// so it never interacts with the order queue.
class PendingRecoveryService {
  static Future<List<PendingRecoveryOrder>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPendingRecoveryKey);
      if (raw == null || raw.isEmpty) return [];
      return PendingRecoveryOrder.decodeList(raw);
    } catch (e) {
      log('PendingRecoveryService.getAll error: $e');
      return [];
    }
  }

  static Future<void> _saveAll(List<PendingRecoveryOrder> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _kPendingRecoveryKey, PendingRecoveryOrder.encodeList(orders));
  }

  static Future<void> add(PendingRecoveryOrder order) async {
    final all = await getAll();
    all.add(order);
    await _saveAll(all);
  }

  static Future<void> remove(String localId) async {
    final all = await getAll();
    all.removeWhere((o) => o.localId == localId);
    await _saveAll(all);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPendingRecoveryKey);
  }

  static Future<int> count() async => (await getAll()).length;
}
