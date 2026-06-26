// lib/infrastructure/services/pending_sync_service.dart
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/pending_sync_order.dart';

const String _kPendingSyncKey = 'pending_sync_orders';

/// Local-only persistence for orders punched while offline (or while the
/// create-order API call failed/timed out). Parallel in spirit to
/// DraftProvider, but for orders that are already "complete" from the
/// salesperson's point of view — they just haven't reached the backend yet.
class PendingSyncService {
  static Future<List<PendingSyncOrder>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kPendingSyncKey);
      if (raw == null || raw.isEmpty) return [];
      return PendingSyncOrder.decodeList(raw);
    } catch (e) {
      log('PendingSyncService.getAll error: $e');
      return [];
    }
  }

  static Future<void> _saveAll(List<PendingSyncOrder> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPendingSyncKey, PendingSyncOrder.encodeList(orders));
  }

  /// Adds a new pending order to the local queue.
  static Future<void> add(PendingSyncOrder order) async {
    final all = await getAll();
    all.add(order);
    await _saveAll(all);
  }

  /// Removes a single pending order by its local id (call after a
  /// successful sync, or when the user explicitly deletes it).
  static Future<void> remove(String localId) async {
    final all = await getAll();
    all.removeWhere((o) => o.localId == localId);
    await _saveAll(all);
  }

  /// Clears the entire queue (e.g. after a full successful sync-all).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPendingSyncKey);
  }

  static Future<int> count() async => (await getAll()).length;
}