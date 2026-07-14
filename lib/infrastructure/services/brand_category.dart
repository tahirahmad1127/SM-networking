import 'package:dartz/dartz.dart';
import 'package:sm_networking/configurations/end_points.dart';
import 'package:sm_networking/infrastructure/api_helper.dart';
import 'package:sm_networking/infrastructure/model/error.dart';
import 'package:sm_networking/infrastructure/model/product.dart';

import '../model/brand_category.dart';
import 'auth_token_helper.dart';

class BrandCategoryService {
  /// GET category/brand/{brandId}
  Future<Either<GlobalErrorModel, BrandCategoryListingModel>>
  getCategoriesByBrand(String brandId) async {
    final token = await getAuthToken();
    final data = await ApiBaseHelper().getEither(
      endPoint: ApiEndPoints.kGetCategoriesByBrand + brandId,
      isRequiredHeader: true,
      header: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'x-auth-token': token,
      },
    );
    return data.fold(
          (l) => Left(GlobalErrorModel(error: l.error.toString())),
          (r) => Right(BrandCategoryListingModel.fromJson(r)),
    );
  }

  /// GET product/by-brand/{brandId}/category/{categoryId}?page=&limit=&searchTerm=
  /// Returns only products belonging to the specific brand AND category.
  Future<Either<GlobalErrorModel, ProductListingModel>> getProductsByBrandAndCategory({
    required String brandId,
    required String categoryID,
    required int page,
    int limit = 10,
    String? searchTerm,
  }) async {
    final token = await getAuthToken();
    final data = await ApiBaseHelper().getEither(
      endPoint: ApiEndPoints.kGetProductsByBrandAndCategoryPaginated(
        brandId: brandId,
        categoryId: categoryID,
        page: page,
        limit: limit,
        searchTerm: searchTerm,
      ),
      isRequiredHeader: true,
      header: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'x-auth-token': token,
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
    String? brandId,
    String? categoryId,
    int page = 1,
    int limit = 10,
  }) async {
    final token = await getAuthToken();
    final data = await ApiBaseHelper().getEither(
      endPoint: ApiEndPoints.kProductSearch(
        searchTerm: searchTerm,
        brandId: brandId,
        categoryId: categoryId,
        page: page,
        limit: limit,
      ),
      isRequiredHeader: true,
      header: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'x-auth-token': token,
      },
    );
    return data.fold(
          (l) => Left(GlobalErrorModel(error: l.error.toString())),
          (r) => Right(ProductListingModel.fromJson(r)),
    );
  }

  /// GET product/category/{categoryId}?page=&limit=&searchTerm=
  Future<Either<GlobalErrorModel, ProductListingModel>> getProductsByCategory({
    required String categoryID,
    required int page,
    int limit = 10,
    String? searchTerm,
  }) async {
    final token = await getAuthToken();
    final data = await ApiBaseHelper().getEither(
      endPoint: ApiEndPoints.kGetProductsByCategoryPaginated(
        categoryId: categoryID,
        page: page,
        limit: limit,
        searchTerm: searchTerm,
      ),
      isRequiredHeader: true,
      header: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'x-auth-token': token,
      },
    );
    return data.fold(
          (l) => Left(GlobalErrorModel(error: l.error.toString())),
          (r) => Right(ProductListingModel.fromJson(r)),
    );
  }
}