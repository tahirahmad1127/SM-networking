import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:sm_networking/infrastructure/model/product.dart';

import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/error.dart';
import 'auth_token_helper.dart';

abstract class ProductRepository {
  Future<Either<GlobalErrorModel, ProductListingModel>> getProducts({
    required String cityID,
    required String categoryID,
    required String brandID,
    required int page,
  });

  Future<Either<GlobalErrorModel, ProductListingModel>> getProductsByBrandID(
      String brandID);

  Future<Either<GlobalErrorModel, ProductModel>> getProductByID(
      String productID);

  Future<Either<GlobalErrorModel, ProductListingModel>> getProductsByCategory({
    required String categoryID,
    required int page,
    int limit = 10,
    String? searchTerm,
  });
}

class ProductRepositoryImp extends ProductRepository {
  @override
  Future<Either<GlobalErrorModel, ProductListingModel>> getProducts({
    required String cityID,
    required String categoryID,
    required String brandID,
    required int page,
  }) async {
    if (brandID.isNotEmpty) {
      return getProductsByBrandID(brandID);
    }

    final String endpoint =
        '${ApiEndPoints.kGetProducts}/category/$categoryID?page=$page';
    log('ProductRepo.getProducts → $endpoint');

    final token = await getAuthToken();
    final data = await ApiBaseHelper().getEither(
      endPoint: endpoint,
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

  @override
  Future<Either<GlobalErrorModel, ProductListingModel>> getProductsByBrandID(
      String brandID) async {
    final token = await getAuthToken();
    final data = await ApiBaseHelper().getEither(
      endPoint: '${ApiEndPoints.kGetBrandDetail}$brandID',
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

  @override
  Future<Either<GlobalErrorModel, ProductModel>> getProductByID(
      String productID) async {
    final token = await getAuthToken();
    final data = await ApiBaseHelper().getEither(
      endPoint: '${ApiEndPoints.kGetProducts}/$productID',
      isRequiredHeader: true,
      header: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'x-auth-token': token,
      },
    );

    return data.fold(
          (l) => Left(GlobalErrorModel(error: l.error.toString())),
          (r) {
        final raw = (r['data'] is Map<String, dynamic>) ? r['data'] : r;
        return Right(ProductModel.fromJson(raw as Map<String, dynamic>));
      },
    );
  }

  @override
  Future<Either<GlobalErrorModel, ProductListingModel>> getProductsByCategory({
    required String categoryID,
    required int page,
    int limit = 10,
    String? searchTerm,
  }) async {
    // "All" tab selected — no category filter, return empty so UI stays clean
    if (categoryID.isEmpty) {
      return Right(ProductListingModel(msg: "success", data: []));
    }

    final String endpoint = ApiEndPoints.kGetProductsByCategoryPaginated(
      categoryId: categoryID,
      page: page,
      limit: limit,
      searchTerm: searchTerm,
    );
    log('ProductRepo.getProductsByCategory → $endpoint');

    final token = await getAuthToken();
    final data = await ApiBaseHelper().getEither(
      endPoint: endpoint,
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