import 'dart:developer';

import 'package:dartz/dartz.dart';

import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/add_recovery.dart';
import '../model/error.dart';
import '../model/order.dart';

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
}