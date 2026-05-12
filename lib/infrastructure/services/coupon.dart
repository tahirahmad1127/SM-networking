// lib/infrastructure/services/coupon.dart

import 'dart:developer';
import 'package:dartz/dartz.dart';
import 'package:sm_networking/configurations/end_points.dart';
import 'package:sm_networking/infrastructure/api_helper.dart';
import 'package:sm_networking/infrastructure/model/coupon.dart';
import 'package:sm_networking/infrastructure/model/error.dart';

abstract class CouponRepository {
  Future<Either<GlobalErrorModel, CouponModel>> applyCoupon(Map<String, dynamic> body);
}

class CouponRepositoryImp extends CouponRepository {
  
  final ApiBaseHelper _apiHelper = ApiBaseHelper();

  @override
  Future<Either<GlobalErrorModel, CouponModel>> applyCoupon(Map<String, dynamic> body) async {
    log("🎟️ Sending Coupon Apply Request: $body");

    final data = await _apiHelper.postEither(
      endPoint: ApiEndPoints.kApplyCoupon,
      isRequiredHeader: true,
      hasBody: true,
      body: body,
      header: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    return data.fold(
          (l) => Left(GlobalErrorModel(error: l.error)),
          (r) {
        final parsed = r['data'];
        return Right(CouponModel.fromJson(parsed));
      },
    );
  }
}
