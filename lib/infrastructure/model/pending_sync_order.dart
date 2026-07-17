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

/// Visit metadata captured when an order is queued while Offline Mode is
/// on — the visit-add API call (VisitRepositoryImp.addVisit) is deferred
/// the same way the order itself is, and replayed at sync time alongside
/// it. [localImagePath] points at a file in a persistent app directory
/// (not a temp/cache path) so it survives until sync — see
/// offline_visit_image_store.dart.
class PendingVisitInfo {
  final String retailerId;
  final String salesPersonId;
  final String shopName;
  final String startTime;
  final String endTime;
  final String date;
  final String? localImagePath;

  PendingVisitInfo({
    required this.retailerId,
    required this.salesPersonId,
    required this.shopName,
    required this.startTime,
    required this.endTime,
    required this.date,
    this.localImagePath,
  });

  Map<String, dynamic> toJson() => {
    'retailerId': retailerId,
    'salesPersonId': salesPersonId,
    'shopName': shopName,
    'startTime': startTime,
    'endTime': endTime,
    'date': date,
    'localImagePath': localImagePath,
  };

  factory PendingVisitInfo.fromJson(Map<String, dynamic> j) {
    return PendingVisitInfo(
      retailerId: j['retailerId'] ?? '',
      salesPersonId: j['salesPersonId'] ?? '',
      shopName: j['shopName'] ?? '',
      startTime: j['startTime'] ?? '',
      endTime: j['endTime'] ?? '',
      date: j['date'] ?? '',
      localImagePath: j['localImagePath'],
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

  /// Set only when this order was queued from Offline Mode's checkout flow
  /// and a visit was started — null for the pre-existing "connectivity
  /// dropped mid-order" queue path, which never captured a visit here.
  final PendingVisitInfo? visitInfo;

  /// Whether [visitInfo]'s image/visit record has already been uploaded —
  /// lets a retried sync skip re-uploading an image that already succeeded.
  final bool visitSynced;

  PendingSyncOrder({
    required this.localId,
    required this.model,
    required this.customerName,
    required this.total,
    required this.createdAt,
    this.itemInfo = const [],
    this.visitInfo,
    this.visitSynced = false,
  });

  PendingSyncOrder copyWith({bool? visitSynced}) => PendingSyncOrder(
    localId: localId,
    model: model,
    customerName: customerName,
    total: total,
    createdAt: createdAt,
    itemInfo: itemInfo,
    visitInfo: visitInfo,
    visitSynced: visitSynced ?? this.visitSynced,
  );

  Map<String, dynamic> toJson() => {
    'localId': localId,
    'model': model.toJson(),
    'customerName': customerName,
    'total': total,
    'createdAt': createdAt.toIso8601String(),
    'itemInfo': itemInfo.map((e) => e.toJson()).toList(),
    'visitInfo': visitInfo?.toJson(),
    'visitSynced': visitSynced,
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
      // Both absent on any order queued before this field existed —
      // treated as "no visit to sync", which is correct for that path.
      visitInfo: j['visitInfo'] == null
          ? null
          : PendingVisitInfo.fromJson(
          Map<String, dynamic>.from(j['visitInfo'])),
      visitSynced: j['visitSynced'] ?? false,
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