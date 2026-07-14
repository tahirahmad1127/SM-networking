import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:sm_networking/infrastructure/model/stats.dart';

import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/error.dart';

abstract class StatsRepository {
  Future<Either<GlobalErrorModel, StatsListingModel>> getStats(
      String userID, String role);
}

class StatsRepositoryImp extends StatsRepository {
  @override
  Future<Either<GlobalErrorModel, StatsListingModel>> getStats(
      String userID, String role) async {
    // Call 1: existing sales stats
    final salesData = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kGetStats + userID,
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });

    return salesData.fold((l) {
      return Left(GlobalErrorModel(error: l.error.toString()));
    }, (r) async {
      StatsListingModel statsModel = StatsListingModel.fromJson(r);

      // Pick the correct target endpoint based on role
      final String targetEndpoint = (role == 'orderbooker')
          ? ApiEndPoints.kGetTargetsOrderbooker + userID
          : ApiEndPoints.kGetTargets + userID;

      // Call 2: targets endpoint to get real achievedTarget / totalTarget
      final targetData = await ApiBaseHelper().getEither(
          endPoint: targetEndpoint,
          isRequiredHeader: true,
          header: {
            'Accept': 'application/json',
            'Content-Type': 'application/json'
          });

      targetData.fold((l) {
        log('⚠️ Targets API failed: ${l.error}');
        // If targets call fails, just continue with sales data as-is
      }, (targetJson) {
        log('✅ Targets API response: $targetJson');

        // Response shape: { "msg": "success", "data": [ { "target": 3100, "achieved": 0, ... } ] }
        final List dataList =
            targetJson['data'] is List ? targetJson['data'] : [];
        final Map<String, dynamic> firstTarget =
            dataList.isNotEmpty ? Map<String, dynamic>.from(dataList[0]) : {};

        final num totalTarget = firstTarget['target'] ??
            firstTarget['totalTarget'] ??
            statsModel.data?.totalTarget ??
            0;
        final num achievedTarget = firstTarget['achieved'] ??
            firstTarget['achievedTarget'] ??
            statsModel.data?.achievedTarget ??
            0;
        final num remainingTarget = (totalTarget - achievedTarget) < 0
            ? 0
            : (totalTarget - achievedTarget);

        statsModel = StatsListingModel(
          msg: statsModel.msg,
          data: StatModel(
            orders: statsModel.data?.orders,
            shops: statsModel.data?.shops,
            sales: statsModel.data?.sales,
            todaySales: statsModel.data?.todaySales,
            monthsSales: statsModel.data?.monthsSales,
            totalTarget: totalTarget,
            achievedTarget: achievedTarget,
            remainingTarget: remainingTarget,
          ),
        );
      });

      return Right(statsModel);
    });
  }
}
