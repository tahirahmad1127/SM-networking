// lib/infrastructure/model/pending_sync_order.dart
import 'dart:convert';

import 'create_order.dart';

/// Display-only product info captured at the moment an order is queued
/// offline. Kept separate from [OrderItem] (the API payload) so we never
/// accidentally send extra fields to the backend, while still being able
/// to show a real product name/image on the Pending Sync details screen.
class PendingSyncItemInfo {
  final String productName;
  final String productImage;

  PendingSyncItemInfo({
    required this.productName,
    required this.productImage,
  });

  Map<String, dynamic> toJson() => {
    'productName': productName,
    'productImage': productImage,
  };

  factory PendingSyncItemInfo.fromJson(Map<String, dynamic> j) {
    return PendingSyncItemInfo(
      productName: j['productName'] ?? '',
      productImage: j['productImage'] ?? '',
    );
  }
}

/// An order that was punched while offline (or while the API was
/// unreachable) and is waiting to be pushed to the backend.
///
/// Stored locally in SharedPreferences as a JSON list, separate from the
/// existing on-server "Draft" concept — this is purely a client-side queue
/// for orders that the salesperson has already completed at the point of
/// sale, just not yet synced.
class PendingSyncOrder {
  final String localId; // local UUID, used for sync/delete by id
  final CreateOrderModel model;
  final String customerName; // for display in the Pending Sync list
  final double total; // for display in the Pending Sync list
  final DateTime createdAt;

  /// Display-only info per item, in the same order as model.items.
  /// Kept separate from the API payload (see PendingSyncItemInfo).
  final List<PendingSyncItemInfo> itemInfo;

  PendingSyncOrder({
    required this.localId,
    required this.model,
    required this.customerName,
    required this.total,
    required this.createdAt,
    this.itemInfo = const [],
  });

  Map<String, dynamic> toJson() => {
    'localId': localId,
    'model': model.toJson(),
    'customerName': customerName,
    'total': total,
    'createdAt': createdAt.toIso8601String(),
    'itemInfo': itemInfo.map((e) => e.toJson()).toList(),
  };

  factory PendingSyncOrder.fromJson(Map<String, dynamic> j) {
    return PendingSyncOrder(
      localId: j['localId'] ?? '',
      model: CreateOrderModel.fromJson(
          Map<String, dynamic>.from(j['model'] ?? {})),
      customerName: j['customerName'] ?? '',
      total: (j['total'] ?? 0).toDouble(),
      createdAt:
      DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
      itemInfo: (j['itemInfo'] as List? ?? [])
          .map((e) =>
          PendingSyncItemInfo.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  static String encodeList(List<PendingSyncOrder> orders) =>
      jsonEncode(orders.map((o) => o.toJson()).toList());

  static List<PendingSyncOrder> decodeList(String raw) {
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => PendingSyncOrder.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}