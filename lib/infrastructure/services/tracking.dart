// tracking_repository.dart
import 'dart:developer';
import 'package:dartz/dartz.dart';
import 'package:sm_networking/configurations/end_points.dart';
import 'package:sm_networking/infrastructure/api_helper.dart';
import 'package:sm_networking/infrastructure/model/error.dart';

import '../model/tracking.dart';

abstract class TrackingRepository {
  Future<Either<GlobalErrorModel, TrackingResponseModel>> sendCoordinates(Map<String, dynamic> body);
}

class TrackingRepositoryImp extends TrackingRepository {
  final ApiBaseHelper _apiHelper = ApiBaseHelper();

  @override
  Future<Either<GlobalErrorModel, TrackingResponseModel>> sendCoordinates(
      Map<String, dynamic> body) async {
    log("📍 Sending Coordinates: $body");

    try {
      final data = await _apiHelper.postEither(
        endPoint: ApiEndPoints.kSendCoordinates,
        isRequiredHeader: true,
        hasBody: true,
        body: body,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      return data.fold((l) {
          log("❌ Tracking Error: ${l.error}");
          return Left(GlobalErrorModel(error: l.error));
        }, (r) {
          log("✅ Tracking Success: ${r['msg']}");
          return Right(TrackingResponseModel.fromJson(r));
        },
      );
    } catch (e, s) {
      log("❌ Tracking Exception: $e\n$s");
      return Left(GlobalErrorModel(error: e.toString()));
    }
  }
}