import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:sm_networking/infrastructure/model/product.dart';

import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/error.dart';

abstract class ProductRepository {
  Future<Either<GlobalErrorModel, ProductListingModel>> getProducts(
      {required String cityID,
        required String categoryID,
        required String brandID,
        required int page});

  Future<Either<GlobalErrorModel, ProductListingModel>> getProductsByBrandID(
      String brandID);

  Future<Either<GlobalErrorModel, ProductModel>> getProductByID(
      String productID);
}

class ProductRepositoryImp extends ProductRepository {
  @override
  @override
  Future<Either<GlobalErrorModel, ProductListingModel>> getProducts({
    required String cityID,
    required String categoryID,
    required String brandID,
    required int page,
  }) async {
    // When a brand is selected, use the brand detail endpoint (it includes all products)
    if (brandID.isNotEmpty) {
      return getProductsByBrandID(brandID);
    }

    final String endpoint =
        '${ApiEndPoints.kGetProducts}/category/$categoryID?page=$page';

    log('ProductRepo.getProducts → $endpoint');

    final data = await ApiBaseHelper().getEither(
      endPoint: endpoint,
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

  @override
  Future<Either<GlobalErrorModel, ProductListingModel>> getProductsByBrandID(
      String brandID) async {
    // brand/{brandID} returns: { "msg": "success", "brand": {...}, "products": [...] }
    // ProductListingModel.fromJson reads either "products" or "data" key.
    final data = await ApiBaseHelper().getEither(
        endPoint: '${ApiEndPoints.kGetBrandDetail}$brandID',
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        });

    return data.fold(
          (l) => Left(GlobalErrorModel(error: l.error.toString())),
          (r) => Right(ProductListingModel.fromJson(r)),
    );
  }

  @override
  Future<Either<GlobalErrorModel, ProductModel>> getProductByID(
      String productID) async {
    final data = await ApiBaseHelper().getEither(
        endPoint: '${ApiEndPoints.kGetProducts}/$productID',
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        });

    return data.fold(
          (l) => Left(GlobalErrorModel(error: l.error.toString())),
          (r) {
        // Some endpoints wrap the product under a "data" key, some don't.
        final raw = (r['data'] is Map<String, dynamic>) ? r['data'] : r;
        return Right(ProductModel.fromJson(raw as Map<String, dynamic>));
      },
    );
  }
}