import 'dart:developer';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:sm_networking/infrastructure/model/category.dart';
import 'package:sm_networking/infrastructure/model/retailer.dart';
import 'package:sm_networking/infrastructure/model/terms_condition.dart';
import 'package:sm_networking/infrastructure/model/user.dart';

import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/error.dart';

abstract class SettingRepository {
  Future<Either<GlobalErrorModel, TermsConditionModel>> getTermsCondition();

  Future<Either<GlobalErrorModel, TermsConditionModel>> getPrivacyPolicy();
}

class SettingRepositoryImp extends SettingRepository {
  @override
  Future<Either<GlobalErrorModel, TermsConditionModel>>
      getTermsCondition() async {
    var data = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kGetTermsCondition,
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });
    return data.fold((l) {
      return Left(GlobalErrorModel(error: l.error.toString()));
    }, (r) {
      return Right(TermsConditionModel.fromJson(r));
    });
  }

  @override
  Future<Either<GlobalErrorModel, TermsConditionModel>>
      getPrivacyPolicy() async {
    var data = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kGetPrivacyPolicy,
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });
    return data.fold((l) {
      return Left(GlobalErrorModel(error: l.error.toString()));
    }, (r) {
      return Right(TermsConditionModel.fromJson(r));
    });
  }
}
