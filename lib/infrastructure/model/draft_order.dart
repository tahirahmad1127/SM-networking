// lib/infrastructure/model/draft_order.dart
import 'dart:convert';

import 'cart.dart';

/// A draft order saved locally (not yet sent to backend).
/// Stored in SharedPreferences as a JSON list.
class DraftOrder {
  final String id;           // local UUID
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String shippingAddress;
  final String city;
  final String saleUserId;
  final List<CartModel> items;
  final double total;
  final double bulkDiscount;
  final double couponDiscount;
  final String couponCode;
  final String paymentType;
  final DateTime createdAt;

  DraftOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.shippingAddress,
    required this.city,
    required this.saleUserId,
    required this.items,
    required this.total,
    this.bulkDiscount = 0,
    this.couponDiscount = 0,
    this.couponCode = '',
    this.paymentType = 'cod',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'shippingAddress': shippingAddress,
    'city': city,
    'saleUserId': saleUserId,
    'items': items.map((e) => e.toJson()).toList(),
    'total': total,
    'bulkDiscount': bulkDiscount,
    'couponDiscount': couponDiscount,
    'couponCode': couponCode,
    'paymentType': paymentType,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DraftOrder.fromJson(Map<String, dynamic> j) => DraftOrder(
    id: j['id'] ?? '',
    customerId: j['customerId'] ?? '',
    customerName: j['customerName'] ?? '',
    customerPhone: j['customerPhone'] ?? '',
    shippingAddress: j['shippingAddress'] ?? '',
    city: j['city'] ?? '',
    saleUserId: j['saleUserId'] ?? '',
    items: (j['items'] as List? ?? [])
        .map((e) => CartModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    total: (j['total'] ?? 0).toDouble(),
    bulkDiscount: (j['bulkDiscount'] ?? 0).toDouble(),
    couponDiscount: (j['couponDiscount'] ?? 0).toDouble(),
    couponCode: j['couponCode'] ?? '',
    paymentType: j['paymentType'] ?? 'cod',
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );
}