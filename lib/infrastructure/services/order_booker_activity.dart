import 'dart:developer';

import 'package:dartz/dartz.dart';

import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/add_recovery.dart';
import '../model/error.dart';
import '../model/order.dart';
import '../model/user.dart';

/// Read-only activity for a specific orderBooker, from the perspective of
/// their warehouseManager (TSM). Both endpoints are scoped by
/// `tsmId` (the logged-in warehouseManager's own id) + `orderBookerId`
/// (the tapped OrderBooker's id) — see [OrderBookersListView] →
/// [OrderBookerActionsView].
abstract class OrderBookerActivityRepository {
  Future<Either<GlobalErrorModel, OrderListingModel>> getMarketBookingOrders({
    required String tsmId,
    required String orderBookerId,
    required String token,
  });

  Future<Either<GlobalErrorModel, RecoveryListingModel>> getMarketRecoveries({
    required String tsmId,
    required String orderBookerId,
    required String token,
  });

  /// Recoveries across ALL order bookers under [tsmId] by default; pass
  /// [orderBookerId] to filter to just one. Paginated.
  Future<Either<GlobalErrorModel, RecoveryListingModel>> getAllMarketRecoveries({
    required String tsmId,
    String? orderBookerId,
    required int page,
    required int limit,
    required String token,
  });

  Future<Either<GlobalErrorModel, List<OrderBooker>>> getOrderBookersForTsm({
    required String tsmId,
    required String token,
  });

  /// GET warehouse-manager/{tsmId}/distributors?page=&limit=&searchTerm=&lat=&lng=
  /// — paginated, replaces loading the full `distributors` array embedded
  /// in the login response. lat/lng (TSM's current GPS position) sort
  /// results by proximity, closest first — same behavior as
  /// getWholesalersPaginated/getRetailersPaginated.
  Future<Either<GlobalErrorModel, DistributorsListingModel>> getDistributorsForTsm({
    required String tsmId,
    required int page,
    required int limit,
    String? searchTerm,
    double? lat,
    double? lng,
    required String token,
  });

  Future<Either<GlobalErrorModel, dynamic>> getOrderBookerReport({
    required String tsmId,
    required String orderBookerId,
    required String reportType,
    required String token,
  });
}

class OrderBookerActivityRepositoryImp
    extends OrderBookerActivityRepository {
  /// Sends both auth header conventions used elsewhere in this app
  /// ('x-auth-token' for payment/* routes, 'Authorization: Bearer' for
  /// warehouse-manager/* routes) so this works regardless of which
  /// middleware guards these two new routes.
  Map<String, String> _headers(String token) {
    final rawToken = token.startsWith('Bearer ') ? token.substring(7) : token;
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'x-auth-token': rawToken,
      'Authorization': 'Bearer $rawToken',
    };
  }

  @override
  Future<Either<GlobalErrorModel, OrderListingModel>> getMarketBookingOrders({
    required String tsmId,
    required String orderBookerId,
    required String token,
  }) async {
    try {
      final data = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kMarketBookingOrders(tsmId, orderBookerId),
        isRequiredHeader: true,
        header: _headers(token),
      );
      return data.fold(
            (l) => Left(GlobalErrorModel(error: l.error.toString())),
            (r) => Right(OrderListingModel.fromJson(r)),
      );
    } catch (e) {
      log("getMarketBookingOrders error: $e");
      return Left(GlobalErrorModel(error: e.toString()));
    }
  }

  @override
  Future<Either<GlobalErrorModel, RecoveryListingModel>> getMarketRecoveries({
    required String tsmId,
    required String orderBookerId,
    required String token,
  }) async {
    try {
      final data = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kMarketRecoveries(tsmId, orderBookerId),
        isRequiredHeader: true,
        header: _headers(token),
      );
      return data.fold(
            (l) => Left(GlobalErrorModel(error: l.error.toString())),
            (r) => Right(RecoveryListingModel.fromJson(r)),
      );
    } catch (e) {
      log("getMarketRecoveries error: $e");
      return Left(GlobalErrorModel(error: e.toString()));
    }
  }

  @override
  Future<Either<GlobalErrorModel, RecoveryListingModel>> getAllMarketRecoveries({
    required String tsmId,
    String? orderBookerId,
    required int page,
    required int limit,
    required String token,
  }) async {
    try {
      final data = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kAllMarketRecoveries(
          tsmId: tsmId,
          orderBookerId: orderBookerId,
          page: page,
          limit: limit,
        ),
        isRequiredHeader: true,
        header: _headers(token),
      );
      return data.fold(
            (l) => Left(GlobalErrorModel(error: l.error.toString())),
            (r) => Right(RecoveryListingModel.fromJson(r)),
      );
    } catch (e) {
      log("getAllMarketRecoveries error: $e");
      return Left(GlobalErrorModel(error: e.toString()));
    }
  }

  @override
  Future<Either<GlobalErrorModel, List<OrderBooker>>> getOrderBookersForTsm({
    required String tsmId,
    required String token,
  }) async {
    try {
      final data = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kWarehouseManagerOrderBookers(tsmId),
        isRequiredHeader: true,
        header: _headers(token),
      );

      return data.fold(
            (l) => Left(GlobalErrorModel(error: l.error.toString())),
            (r) {
          final list = <OrderBooker>[];
          if (r is List) {
            for (final item in r) {
              if (item is Map<String, dynamic>) {
                list.add(OrderBooker.fromJson(item));
              }
            }
            return Right(list);
          }

          if (r is Map<String, dynamic>) {
            final rawList = r['data'] ?? r['orderBookers'] ?? r['orderBooker'];
            if (rawList is List) {
              for (final item in rawList) {
                if (item is Map<String, dynamic>) {
                  list.add(OrderBooker.fromJson(item));
                }
              }
              return Right(list);
            }
          }

          return Left(GlobalErrorModel(
              error: 'Unexpected response format for order bookers.'));
        },
      );
    } catch (e) {
      log("getOrderBookersForTsm error: $e");
      return Left(GlobalErrorModel(error: e.toString()));
    }
  }

  @override
  Future<Either<GlobalErrorModel, DistributorsListingModel>> getDistributorsForTsm({
    required String tsmId,
    required int page,
    required int limit,
    String? searchTerm,
    double? lat,
    double? lng,
    required String token,
  }) async {
    try {
      final data = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kGetDistributorsForTsm(
          tsmId: tsmId,
          page: page,
          limit: limit,
          searchTerm: searchTerm,
          lat: lat,
          lng: lng,
        ),
        isRequiredHeader: true,
        header: _headers(token),
      );
      return data.fold(
        (l) => Left(GlobalErrorModel(error: l.error.toString())),
        (r) => Right(DistributorsListingModel.fromJson(r)),
      );
    } catch (e) {
      log("getDistributorsForTsm error: $e");
      return Left(GlobalErrorModel(error: e.toString()));
    }
  }

  @override
  Future<Either<GlobalErrorModel, dynamic>> getOrderBookerReport({
    required String tsmId,
    required String orderBookerId,
    required String reportType,
    required String token,
  }) async {
    try {
      final data = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kOrderBookerReport(
          tsmId: tsmId,
          orderBookerId: orderBookerId,
          type: reportType,
        ),
        isRequiredHeader: true,
        header: _headers(token),
      );
      return data.fold(
            (l) => Left(GlobalErrorModel(error: l.error.toString())),
            (r) {
          if (r is Map<String, dynamic> && r.containsKey('data')) {
            return Right(r['data']);
          }
          return Right(r);
        },
      );
    } catch (e) {
      log("getOrderBookerReport error: $e");
      return Left(GlobalErrorModel(error: e.toString()));
    }
  }
}
