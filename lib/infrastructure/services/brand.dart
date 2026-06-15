import 'package:dartz/dartz.dart';
import 'package:sm_networking/infrastructure/model/brand.dart';

import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/all_brands.dart';
import '../model/error.dart';

abstract class BrandRepository {
  Future<Either<GlobalErrorModel, BrandListingModel>> getBrands(String brandID);
  Future<Either<GlobalErrorModel, AllBrandsListingModel>> getAllBrands();
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

  @override
  Future<Either<GlobalErrorModel, AllBrandsListingModel>> getAllBrands() async {
    var data = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kGetAllBrands,
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });
    return data.fold((l) {
      return Left(GlobalErrorModel(error: l.error.toString()));
    }, (r) {
      return Right(AllBrandsListingModel.fromJson(r));
    });
  }
}