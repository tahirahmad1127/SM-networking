import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/connectivity_status.dart';
import '../infrastructure/model/user.dart';
import '../infrastructure/services/offline_cache_service.dart';
import '../infrastructure/services/offline_customers_service.dart';
import '../infrastructure/services/offline_sync_service.dart';

/// Drives the user-triggered "Offline Mode" toggle on the attendance
/// screen: caching retailers/wholesalers/distributors/products locally
/// while online, then gating several screens (Customers map, View All,
/// Products, checkout) to their offline-capable behavior while the flag is
/// on. Does not touch PendingSyncProvider's queue — that stays independent
/// regardless of this flag.
class OfflineModeProvider extends ChangeNotifier {
  static const String _isOfflineKey = 'IS_OFFLINE_MODE';
  static const String _lastCachedAtKey = 'OFFLINE_LAST_CACHED_AT';

  bool _isOffline = false;
  bool _isCaching = false;
  String? _cacheError;
  DateTime? _lastCachedAt;

  bool get isOffline => _isOffline;
  bool get isCaching => _isCaching;
  String? get cacheError => _cacheError;
  DateTime? get lastCachedAt => _lastCachedAt;

  OfflineModeProvider() {
    _restoreFromPrefs();
  }

  Future<void> _restoreFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isOffline = prefs.getBool(_isOfflineKey) ?? false;
    final lastCached = prefs.getString(_lastCachedAtKey);
    _lastCachedAt = lastCached == null ? null : DateTime.tryParse(lastCached);
    notifyListeners();
  }

  /// Fetches everything needed for offline ordering while still online, and
  /// only flips [isOffline] to true if the customer data caches succeed —
  /// products failing alone still allows offline mode to turn on (the
  /// bulk-products endpoint may be slower/less reliable than the
  /// retailer/wholesaler/distributor fetches), but a total failure across
  /// customer data does not, so the app never ends up "offline" with an
  /// empty, useless cache.
  Future<bool> enableOfflineMode(UserModel userDetails) async {
    final isConnected = await InternetConnectivityHelper.checkConnectivityFast();
    if (!isConnected) {
      _cacheError = "You must be online to enable Offline Mode.";
      notifyListeners();
      return false;
    }

    _isCaching = true;
    _cacheError = null;
    notifyListeners();

    final role = userDetails.role ?? '';

    bool customerDataOk = false;
    String? partialError;

    try {
      final customersService = OfflineCustomersService();

      final wholesalersResult = await customersService.getAllWholesalersOffline();
      final retailersResult = await customersService.getAllRetailersOffline();

      final wholesalers = wholesalersResult.fold((l) {
        log('OfflineModeProvider: wholesalers fetch failed: ${l.error}');
        throw Exception('Wholesalers: ${l.error}');
      }, (r) => r);
      final retailers = retailersResult.fold((l) {
        log('OfflineModeProvider: retailers fetch failed: ${l.error}');
        throw Exception('Retailers: ${l.error}');
      }, (r) => r);

      await OfflineCacheService.saveWholesalers(wholesalers);
      await OfflineCacheService.saveRetailers(retailers);
      log('OfflineModeProvider: cached ${wholesalers.length} wholesaler(s), ${retailers.length} retailer(s)');
      customerDataOk = true;

      if (role == 'warehouseManager') {
        if (userDetails.distributors != null &&
            userDetails.distributors!.isNotEmpty) {
          // Already embedded in the login payload — no API call needed.
          await OfflineCacheService.saveDistributors(userDetails.distributors!);
        } else {
          final distributorsResult =
              await customersService.getAllDistributorsOffline();
          await distributorsResult.fold(
            (l) async {
              log('OfflineModeProvider: distributors fetch failed: ${l.error}');
              partialError ??= "Distributors could not be cached: ${l.error}";
            },
            (distributors) async {
              await OfflineCacheService.saveDistributors(distributors);
              log('OfflineModeProvider: cached ${distributors.length} distributor(s)');
            },
          );
        }
      }
    } catch (e) {
      customerDataOk = false;
      partialError = e.toString();
      log('OfflineModeProvider: customer data caching failed: $e');
    }

    try {
      final productsResult =
          await OfflineSyncService().getAllProductsOffline();
      await productsResult.fold(
        (l) async {
          partialError ??= "Products could not be cached: ${l.error}";
        },
        (products) async {
          await OfflineCacheService.saveProducts(products);
          log('OfflineModeProvider: cached ${products.length} product(s)');
        },
      );
    } catch (e) {
      partialError ??= "Products could not be cached: $e";
      log('OfflineModeProvider: products caching failed: $e');
    }

    _isCaching = false;

    if (!customerDataOk) {
      _cacheError = partialError ??
          "Could not download retailers/wholesalers/distributors for offline use.";
      notifyListeners();
      return false;
    }

    _isOffline = true;
    _cacheError = partialError; // non-fatal — surfaced as a warning, not a block
    _lastCachedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isOfflineKey, true);
    await prefs.setString(_lastCachedAtKey, _lastCachedAt!.toIso8601String());
    notifyListeners();
    return true;
  }

  Future<void> disableOfflineMode() async {
    _isOffline = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isOfflineKey, false);
  }
}
