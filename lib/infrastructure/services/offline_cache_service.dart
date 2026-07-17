import 'dart:convert';
import 'package:hive/hive.dart';

import '../model/offline_product.dart';
import '../model/user.dart';

/// Local cache for Offline Mode — mirrors RetailerCacheService's Hive
/// pattern (retailers_cache.dart) but with its own, separate boxes so this
/// never interacts with the existing online stale-while-revalidate cache
/// that RetailerCacheService already serves.
class OfflineCacheService {
  static const String _wholesalersBoxName = 'offlineWholesalersBox';
  static const String _wholesalersKey = 'cachedOfflineWholesalers';

  static const String _retailersBoxName = 'offlineRetailersBox';
  static const String _retailersKey = 'cachedOfflineRetailers';

  static const String _distributorsBoxName = 'offlineDistributorsBox';
  static const String _distributorsKey = 'cachedOfflineDistributors';

  static const String _productsBoxName = 'offlineProductsBox';
  static const String _productsKey = 'cachedOfflineProducts';

  /// --- Wholesalers ---
  static Future<void> saveWholesalers(List<Wholesaler> wholesalers) async {
    final box = await Hive.openBox(_wholesalersBoxName);
    final jsonList = wholesalers.map((w) => w.toJson()).toList();
    await box.put(_wholesalersKey, jsonEncode(jsonList));
  }

  static Future<List<Wholesaler>> getCachedWholesalers() async {
    final box = await Hive.openBox(_wholesalersBoxName);
    final cached = box.get(_wholesalersKey);
    if (cached != null) {
      final List list = jsonDecode(cached);
      return list.map((e) => Wholesaler.fromJson(e)).toList();
    }
    return [];
  }

  /// --- Retailers (same Wholesaler-shaped model — matches
  /// _PaginatedTabState<Wholesaler> already used for the retailer tab in
  /// retailers_view.dart) ---
  static Future<void> saveRetailers(List<Wholesaler> retailers) async {
    final box = await Hive.openBox(_retailersBoxName);
    final jsonList = retailers.map((r) => r.toJson()).toList();
    await box.put(_retailersKey, jsonEncode(jsonList));
  }

  static Future<List<Wholesaler>> getCachedRetailers() async {
    final box = await Hive.openBox(_retailersBoxName);
    final cached = box.get(_retailersKey);
    if (cached != null) {
      final List list = jsonDecode(cached);
      return list.map((e) => Wholesaler.fromJson(e)).toList();
    }
    return [];
  }

  /// --- Distributors (TSM/warehouseManager only) ---
  static Future<void> saveDistributors(List<Distributor> distributors) async {
    final box = await Hive.openBox(_distributorsBoxName);
    final jsonList = distributors.map((d) => d.toJson()).toList();
    await box.put(_distributorsKey, jsonEncode(jsonList));
  }

  static Future<List<Distributor>> getCachedDistributors() async {
    final box = await Hive.openBox(_distributorsBoxName);
    final cached = box.get(_distributorsKey);
    if (cached != null) {
      final List list = jsonDecode(cached);
      return list.map((e) => Distributor.fromJson(e)).toList();
    }
    return [];
  }

  /// --- Products ---
  static Future<void> saveProducts(List<OfflineProductModel> products) async {
    final box = await Hive.openBox(_productsBoxName);
    final jsonList = products.map((p) => p.toJson()).toList();
    await box.put(_productsKey, jsonEncode(jsonList));
  }

  static Future<List<OfflineProductModel>> getCachedProducts() async {
    final box = await Hive.openBox(_productsBoxName);
    final cached = box.get(_productsKey);
    if (cached != null) {
      final List list = jsonDecode(cached);
      return list.map((e) => OfflineProductModel.fromJson(e)).toList();
    }
    return [];
  }
}
