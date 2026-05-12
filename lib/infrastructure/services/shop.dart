import 'dart:developer';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:sm_networking/infrastructure/model/category.dart';
import 'package:sm_networking/infrastructure/model/order.dart';
import 'package:sm_networking/infrastructure/model/retailer.dart';
import 'package:sm_networking/infrastructure/model/user.dart';

import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/error.dart';

abstract class ShopRepository {
  Future<Either<GlobalErrorModel, dynamic>> tagShop();
}

class ShopRepositoryImp extends ShopRepository {
  @override
  Future<Either<GlobalErrorModel, dynamic>> tagShop() async {
    var data = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kGetOrders,
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });
    return data.fold((l) {
      return Left(GlobalErrorModel(error: l.error.toString()));
    }, (r) {
      return Right(OrderListingModel.fromJson(r));
    });
  }
}
