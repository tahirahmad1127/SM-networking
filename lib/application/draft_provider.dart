// lib/application/draft_provider.dart
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../infrastructure/model/cart.dart';
import '../infrastructure/model/draft_order.dart';

const String _kDraftsKey = 'draft_orders';

class DraftProvider extends ChangeNotifier {
  List<DraftOrder> _drafts = [];

  List<DraftOrder> get drafts => List.unmodifiable(_drafts);

  DraftProvider() {
    _load();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kDraftsKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _drafts = list
            .map((e) => DraftOrder.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      log('DraftProvider._load error: $e');
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kDraftsKey, jsonEncode(_drafts.map((d) => d.toJson()).toList()));
    } catch (e) {
      log('DraftProvider._save error: $e');
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Save a new draft. Returns the generated draft id.
  Future<String> addDraft({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String shippingAddress,
    required String city,
    required String saleUserId,
    required List<CartModel> items,
    required double total,
    double bulkDiscount = 0,
    double couponDiscount = 0,
    String couponCode = '',
    String paymentType = 'cod',
  }) async {
    final id = const Uuid().v4();
    final draft = DraftOrder(
      id: id,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      shippingAddress: shippingAddress,
      city: city,
      saleUserId: saleUserId,
      items: List.from(items),
      total: total,
      bulkDiscount: bulkDiscount,
      couponDiscount: couponDiscount,
      couponCode: couponCode,
      paymentType: paymentType,
      createdAt: DateTime.now(),
    );
    _drafts.insert(0, draft);
    await _save();
    notifyListeners();
    return id;
  }

  Future<void> deleteDraft(String id) async {
    _drafts.removeWhere((d) => d.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _drafts.clear();
    await _save();
    notifyListeners();
  }
}