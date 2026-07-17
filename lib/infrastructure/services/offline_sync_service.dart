import 'dart:developer';

import 'package:dartz/dartz.dart';

import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/error.dart';
import '../model/offline_product.dart';
import 'auth_token_helper.dart';

/// GET offline/sync — bulk product list for Offline Mode. Flat response
/// shape ({success, products: [...]}), not the app's usual {msg, data,
/// total, page, totalPages} envelope, so this is parsed separately from
/// ProductListingModel.
class OfflineSyncService {
  Future<Either<GlobalErrorModel, List<OfflineProductModel>>>
      getAllProductsOffline() async {
    final token = await getAuthToken();
    // Sends both auth header conventions used elsewhere in this app
    // ('x-auth-token' and 'Authorization: Bearer') — mirrors
    // RetailerRepositoryImp._paginatedHeaders, since it's unclear which
    // convention the offline-mode routes' middleware actually checks.
    final rawToken = (token ?? '').startsWith('Bearer ')
        ? token!.substring(7)
        : (token ?? '');
    final data = await ApiBaseHelper().getEither(
      endPoint: ApiEndPoints.kOfflineSync,
      isRequiredHeader: true,
      header: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (rawToken.isNotEmpty) 'x-auth-token': rawToken,
        if (rawToken.isNotEmpty) 'Authorization': 'Bearer $rawToken',
      },
    );
    return data.fold(
      (l) {
        log('OfflineSyncService.getAllProductsOffline FAILED: ${l.error}');
        return Left(GlobalErrorModel(error: l.error.toString()));
      },
      (r) {
        final raw = (r['products'] ?? r['data']) as List<dynamic>? ?? [];
        log('OfflineSyncService.getAllProductsOffline: received ${raw.length} raw product(s)');
        final list = raw
            .map((e) => OfflineProductModel.fromJson(e as Map<String, dynamic>))
            .where((p) => p.isActive)
            .toList();
        log('OfflineSyncService.getAllProductsOffline: ${list.length} active product(s) after filtering');
        return Right(list);
      },
    );
  }
}
