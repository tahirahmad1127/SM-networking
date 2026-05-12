import 'dart:developer';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:sm_networking/infrastructure/model/brand.dart';
import 'package:sm_networking/infrastructure/model/category.dart';
import 'package:sm_networking/infrastructure/model/retailer.dart';
import 'package:sm_networking/infrastructure/model/user.dart';

import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/error.dart';

abstract class BrandRepository {
  Future<Either<GlobalErrorModel, BrandListingModel>> getBrands(String brandID);
}

class BrandRepositoryImp extends BrandRepository {
  @override
  Future<Either<GlobalErrorModel, BrandListingModel>> getBrands(
      String brandID) async {
    var data = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kGetBrands + brandID,
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });
    return data.fold((l) {
      return Left(GlobalErrorModel(error: l.error.toString()));
    }, (r) {
      return Right(BrandListingModel.fromJson(r));
    });
  }
}
