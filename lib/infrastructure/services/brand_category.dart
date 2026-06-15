import 'package:dartz/dartz.dart';
import 'package:sm_networking/configurations/end_points.dart';
import 'package:sm_networking/infrastructure/api_helper.dart';
import 'package:sm_networking/infrastructure/model/error.dart';
import 'package:sm_networking/infrastructure/model/product.dart';

import '../model/brand_category.dart';

class BrandCategoryService {
  /// GET category/brand/{brandId}
  Future<Either<GlobalErrorModel, BrandCategoryListingModel>>
  getCategoriesByBrand(String brandId) async {
    final data = await ApiBaseHelper().getEither(
      endPoint: ApiEndPoints.kGetCategoriesByBrand + brandId,
      isRequiredHeader: true,
      header: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    return data.fold(
          (l) => Left(GlobalErrorModel(error: l.error.toString())),
          (r) => Right(BrandCategoryListingModel.fromJson(r)),
    );
  }

  /// GET product/by-brand/{brandId}/category/{categoryId}?page={page}
  /// Returns only products belonging to the specific brand AND category.
  Future<Either<GlobalErrorModel, ProductListingModel>> getProductsByBrandAndCategory({
    required String brandId,
    required String categoryID,
    required int page,
  }) async {
    final data = await ApiBaseHelper().getEither(
      endPoint: '${ApiEndPoints.kGetProductsByBrandAndCategory}$brandId/category/$categoryID?page=$page',
      isRequiredHeader: true,
      header: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    return data.fold(
          (l) => Left(GlobalErrorModel(error: l.error.toString())),
          (r) => Right(ProductListingModel.fromJson(r)),
    );
  }

  /// GET product/category/{categoryId}?page={page}
  Future<Either<GlobalErrorModel, ProductListingModel>> getProductsByCategory({
    required String categoryID,
    required int page,
  }) async {
    final data = await ApiBaseHelper().getEither(
      endPoint: '${ApiEndPoints.kGetProductsByCategory}$categoryID?page=$page',
      isRequiredHeader: true,
      header: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    return data.fold(
          (l) => Left(GlobalErrorModel(error: l.error.toString())),
          (r) => Right(ProductListingModel.fromJson(r)),
    );
  }
}