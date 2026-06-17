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
      endPoint: '${ApiEndPoints.kGetProductsByBrandAndCategory}$brandId/category/$categoryID?page=$page&limit=500',
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

  /// GET /api/product/search?searchTerm=&brand=&category=&page=&limit=
  Future<Either<GlobalErrorModel, ProductListingModel>> searchProducts({
    required String searchTerm,
    required String brandId,
    String? categoryId,
    int page = 1,
    int limit = 50,
  }) async {
    final params = StringBuffer('product/search?searchTerm=${Uri.encodeComponent(searchTerm)}&brand=$brandId&page=$page&limit=$limit');
    if (categoryId != null && categoryId.isNotEmpty) {
      params.write('&category=$categoryId');
    }
    final data = await ApiBaseHelper().getEither(
      endPoint: params.toString(),
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
      endPoint: '${ApiEndPoints.kGetProductsByCategory}$categoryID?page=$page&limit=500',
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