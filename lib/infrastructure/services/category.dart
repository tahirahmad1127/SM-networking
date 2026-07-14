import 'package:dartz/dartz.dart';
import 'package:sm_networking/infrastructure/model/category.dart';

import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/error.dart';

abstract class CategoryRepository {
  Future<Either<GlobalErrorModel, CategoryListingModel>> getCategories(
      String cityID);
}

class CategoryRepositoryImp extends CategoryRepository {
  // static const String bypass = "?x-vercel-protection-bypass=karyanadevserverkaryanadevserver";
  // static const String bypassAnd = "&x-vercel-protection-bypass=karyanadevserverkaryanadevserver";
  //
  // String _withBypass(String endpoint) {
  //   if (endpoint.contains("?")) {
  //     return "$endpoint$bypassAnd";
  //   }
  //   return "$endpoint$bypass";
  // }

  @override
  Future<Either<GlobalErrorModel, CategoryListingModel>> getCategories(
      String cityID) async {
    var data = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kGetCategories,
        // endPoint: _withBypass(ApiEndPoints.kGetCategories + cityID),
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });
    return data.fold((l) {
      return Left(GlobalErrorModel(error: l.error.toString()));
    }, (r) {
      return Right(CategoryListingModel.fromJson(r));
    });
  }
}
