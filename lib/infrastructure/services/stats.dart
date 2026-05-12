import 'dart:developer';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:sm_networking/infrastructure/model/category.dart';
import 'package:sm_networking/infrastructure/model/retailer.dart';
import 'package:sm_networking/infrastructure/model/stats.dart';
import 'package:sm_networking/infrastructure/model/user.dart';

import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/error.dart';

abstract class StatsRepository {
  Future<Either<GlobalErrorModel, StatsListingModel>> getStats(String userID);
}

class StatsRepositoryImp extends StatsRepository {

  // static const String bypass = "?x-vercel-protection-bypass=karyanadevserverkaryanadevserver";
  // static const String bypassAnd = "&x-vercel-protection-bypass=karyanadevserverkaryanadevserver";

  @override
  Future<Either<GlobalErrorModel, StatsListingModel>> getStats(
      String userID) async {
    var data = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kGetStats + userID,
        // endPoint: "${ApiEndPoints.kGetStats}$userID$bypass",
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });
    return data.fold((l) {
      return Left(GlobalErrorModel(error: l.error.toString()));
    }, (r) {
      return Right(StatsListingModel.fromJson(r));
    });
  }
}
