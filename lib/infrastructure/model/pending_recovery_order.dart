// lib/infrastructure/model/pending_recovery_order.dart
import 'dart:convert';

import 'add_recovery.dart';

/// An "Add Recovery" payment that was recorded while offline and is
/// waiting to be pushed to the backend. Stored locally in SharedPreferences
/// as a JSON list, parallel to PendingSyncOrder but for recoveries instead
/// of orders — kept as a separate queue/model since AddRecoveryModel has a
/// completely different shape from CreateOrderModel, not because the sync
/// mechanism itself differs.
class PendingRecoveryOrder {
  final String localId; // local UUID, used for sync/delete by id
  final AddRecoveryModel model;
  final DateTime createdAt;

  PendingRecoveryOrder({
    required this.localId,
    required this.model,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'model': model.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingRecoveryOrder.fromJson(Map<String, dynamic> j) {
    return PendingRecoveryOrder(
      localId: j['localId'] ?? '',
      model:
          AddRecoveryModel.fromJson(Map<String, dynamic>.from(j['model'] ?? {})),
      createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  static String encodeList(List<PendingRecoveryOrder> orders) =>
      jsonEncode(orders.map((o) => o.toJson()).toList());

  static List<PendingRecoveryOrder> decodeList(String raw) {
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => PendingRecoveryOrder.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
