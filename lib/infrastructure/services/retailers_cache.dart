import 'dart:convert';
import 'package:hive/hive.dart';
import '../model/retailer.dart';

import '../model/banks.dart';

class RetailerCacheService {
  static const String _retailerBoxName = 'retailersBox';
  static const String _retailerKey = 'cachedRetailers';

  static const String _banksBoxName = 'banksBox';
  static const String _banksKey = 'cachedBanks';

  /// --- Retailers ---
  static Future<void> saveRetailers(List<RetailerModel> retailers) async {
    final box = await Hive.openBox(_retailerBoxName);
    final jsonList = retailers.map((r) => r.toJson()).toList();
    await box.put(_retailerKey, jsonEncode(jsonList));
  }

  static Future<List<RetailerModel>?> getCachedRetailers() async {
    final box = await Hive.openBox(_retailerBoxName);
    final cached = box.get(_retailerKey);
    if (cached != null) {
      final List list = jsonDecode(cached);
      return list.map((e) => RetailerModel.fromJson(e)).toList();
    }
    return null;
  }

  static Future<void> clearRetailersCache() async {
    final box = await Hive.openBox(_retailerBoxName);
    await box.delete(_retailerKey);
  }

  /// --- Banks ---
  /// Save banks list to Hive
  static Future<void> saveBanks(List<BankModel> banks) async {
    final box = await Hive.openBox(_banksBoxName);
    final jsonList = banks.map((b) => b.toJson()).toList();
    await box.put(_banksKey, jsonEncode(jsonList));
  }

  /// Load cached banks
  static Future<List<BankModel>?> getCachedBanks() async {
    final box = await Hive.openBox(_banksBoxName);
    final cached = box.get(_banksKey);
    if (cached != null) {
      final List list = jsonDecode(cached);
      return list.map((e) => BankModel.fromJson(e)).toList();
    }
    return null;
  }

  static Future<void> clearBanksCache() async {
    final box = await Hive.openBox(_banksBoxName);
    await box.delete(_banksKey);
  }
}

