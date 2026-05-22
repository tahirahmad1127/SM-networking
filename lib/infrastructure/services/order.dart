import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:sm_networking/infrastructure/model/category.dart';
import 'package:sm_networking/infrastructure/model/create_order.dart';
import 'package:sm_networking/infrastructure/model/order.dart';
import 'package:sm_networking/infrastructure/model/retailer.dart';
import 'package:sm_networking/infrastructure/model/user.dart';

import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/error.dart';

abstract class OrderRepository {
  Future<Either<GlobalErrorModel, dynamic>> createOrder(CreateOrderModel model);

  Future<Either<GlobalErrorModel, dynamic>> cancelOrder(String orderID);

  Future<Either<GlobalErrorModel, OrderListingModel>> getPendingOrders(
      String userID);

  Future<Either<GlobalErrorModel, OrderListingModel>> getProcessedOrders(
      String userID);

  Future<Either<GlobalErrorModel, OrderListingModel>> getCompletedOrders(
      String userID);

  Future<Either<GlobalErrorModel, OrderListingModel>> getCancelledOrders(
      String userID);
}

class OrderRepositoryImp extends OrderRepository {

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
  Future<Either<GlobalErrorModel, OrderListingModel>> getCancelledOrders(
      String userID) async {
    var data = await ApiBaseHelper().postEither(
        endPoint: ApiEndPoints.kGetOrders,
        // endPoint: _withBypass(ApiEndPoints.kGetOrders),
        isRequiredHeader: true,
        hasBody: true,
        body: {
          "status": "Cancelled",
          "salePerson": userID
        },
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

  @override
  Future<Either<GlobalErrorModel, OrderListingModel>> getCompletedOrders(
      String userID) async {
    var data = await ApiBaseHelper().postEither(
        endPoint: ApiEndPoints.kGetOrders,
        // endPoint: _withBypass(ApiEndPoints.kGetOrders),
        isRequiredHeader: true,
        hasBody: true,
        body: {
          "status": "Completed",
          "salePerson": userID
        },
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

  @override
  Future<Either<GlobalErrorModel, OrderListingModel>> getPendingOrders(
      String userID) async {
    var data = await ApiBaseHelper().postEither(
        endPoint: ApiEndPoints.kGetOrders,
        // endPoint: _withBypass(ApiEndPoints.kGetOrders),
        hasBody: true,
        body: {"status": "Placed", "salePerson": userID},
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

  @override
  Future<Either<GlobalErrorModel, OrderListingModel>> getProcessedOrders(
      String userID) async {
    var data = await ApiBaseHelper().postEither(
        endPoint: ApiEndPoints.kGetOrders,
        // endPoint: _withBypass(ApiEndPoints.kGetOrders),
        isRequiredHeader: true,
        hasBody: true,
        body: {
          "status": "Processed",
          "salePerson": userID
        },
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });
    return data.fold((l) {
      return Left(GlobalErrorModel(error: l.error.toString()));
    }, (r) {
      log(r.toString());
      return Right(OrderListingModel.fromJson(r));
    });
  }

  @override
  Future<Either<GlobalErrorModel, dynamic>> createOrder(CreateOrderModel model) async {
    var data = await ApiBaseHelper().postEither(
        endPoint: ApiEndPoints.kAddOrder,
        isRequiredHeader: true,
        hasBody: true,
        body: {
          "warehouseManager": model.retailerUser.toString(),
          "salesPerson": model.saleUser,
          "phoneNumber": model.phoneNumber,
          "paymentType": model.paymentType,
          "shippingAddress": model.shippingAddress,
          "city": model.city.toString(),
          "bulkDiscount": model.bulkDiscount ?? 0,
          "couponDiscount": model.couponDiscount ?? 0,
          "couponCode": model.couponCode,
          "items": model.items!.map((e) => e.toJson()).toList()
        },

        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });
    log( {
      "warehouseManager": model.retailerUser.toString(),
      "salesPerson": model.saleUser,
      "phoneNumber": model.phoneNumber,
      "paymentType": model.paymentType,
      "shippingAddress": model.shippingAddress,
      "city": model.city.toString(),
      "bulkDiscount": model.bulkDiscount ?? 0,
      "couponDiscount": model.couponDiscount ?? 0,
      "couponCode": model.couponCode,
      "items": model.items!.map((e) => e.toJson()).toList()
    }.toString());

    return data.fold((l) {
      log(l.error.toString());
      return Left(GlobalErrorModel(error: l.error.toString()));
    }, (r) {
      log(r['data'].toString());
      return Right(r);
    });
  }

  @override
  Future<Either<GlobalErrorModel, dynamic>> cancelOrder(String orderID) async {
    // final fullEndpoint = ApiEndPoints.kUpdateOrderStatus + orderID;
    var data = await ApiBaseHelper().postEither(
        endPoint: ApiEndPoints.kUpdateOrderStatus + orderID,
        // endPoint: _withBypass(fullEndpoint),
        isRequiredHeader: true,
        hasBody: true,
        body: {
          "status": "Cancelled"
        },
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });
    return data.fold((l) {
      return Left(GlobalErrorModel(error: l.error.toString()));
    }, (r) {
      return Right(r);
    });
  }
}