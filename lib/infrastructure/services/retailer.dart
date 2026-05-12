import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:geocoding/geocoding.dart';

import 'package:dartz/dartz.dart';
import 'package:sm_networking/infrastructure/model/add_retailer.dart';
import 'package:sm_networking/infrastructure/model/retailer.dart';
import 'package:sm_networking/infrastructure/model/user.dart';

import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/add_recovery.dart';
import '../model/banks.dart';
import '../model/error.dart';

abstract class RetailerRepository {
  Future<Either<GlobalErrorModel, RetailersListingModel>> getRetailers(String cityID);

  Future<Either<GlobalErrorModel, RetailerModel>> addRetailer(AddRetailerModel model);

  Future<Either<GlobalErrorModel, RetailerModel>> updateRetailerLocation({required String retailerId, required double lat, required double lng,});

  Future<Either<GlobalErrorModel, BanksListModel>> getAllBanks();

  Future<Either<GlobalErrorModel, RecoveryModel>> addRecovery(AddRecoveryModel model);

}

class RetailerRepositoryImp extends RetailerRepository {

  // static const String bypass = "?x-vercel-protection-bypass=karyanadevserverkaryanadevserver";
  // static const String bypassAnd = "&x-vercel-protection-bypass=karyanadevserverkaryanadevserver";
  //
  // String _withBypass(String endpoint) {
  //   if (endpoint.contains("?")) return "$endpoint$bypassAnd";
  //   return "$endpoint$bypass";
  // }

  @override
  Future<Either<GlobalErrorModel, RetailersListingModel>> getRetailers(String cityID) async {
    var data = await ApiBaseHelper().getEither(
        endPoint: "${ApiEndPoints.kGetRetailers}$cityID?page=1&limit=10000",
        // endPoint: "${ApiEndPoints.kGetRetailers}$cityID?page=1&limit=10000$bypassAnd",
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });
    return data.fold((l) {
      return Left(GlobalErrorModel(error: l.error.toString()));
    }, (r) {
      return Right(RetailersListingModel.fromJson(r));
    });
  }

  @override
  Future<Either<GlobalErrorModel, RetailerModel>> addRetailer(AddRetailerModel model) async {
    try {
      final hasFile = model.file != null && model.file!.isNotEmpty;
      final hasCnic = model.cnic != null && model.cnic!.isNotEmpty;

      final Map<String, String> body = {
        'shopName': model.shopName.toString(),
        'shopCategory': model.shopCategory.toString(),
        'shopAddress2': model.shopAddress2.toString(),
        'shopAddress1': model.shopAddress1.toString(),
        'name': model.name.toString(),
        'phoneNumber': model.phoneNumber.toString(),
        'lat': model.lat.toString(),
        'lng': model.lng.toString(),
        'distance': model.distance.toString(),
        'salesPersonID': model.salesPersonId.toString(),
        'userId': Random().nextInt(1000000).toString(),
        'cityID': model.cityId.toString()
      };

      // Only add CNIC if it's not empty
      if (hasCnic) {
        body['cnic'] = model.cnic!;
      }

      var data = await ApiBaseHelper().postMultiPartEither(
        endPoint: ApiEndPoints.kAddRetailer,
        body: body,
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        hasBody: true,
        hasFile: hasFile,
        path: hasFile ? model.file! : null,
      );

      return data.fold((l) {
        return Left(GlobalErrorModel(error: l.error.toString()));
      }, (r) {
        return Right(RetailerModel.fromJson(r['data']));
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Either<GlobalErrorModel, RetailerModel>> updateRetailerLocation({required String retailerId, required double lat, required double lng,}) async {
    try {
      // Reverse geocode lat/lng → human-readable address
      String shopAddress1 = '';
      try {
        final placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          // Build address from most specific to least specific
          final parts = [
            p.name,
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
          ].where((s) => s != null && s.isNotEmpty).toList();
          shopAddress1 = parts.join(', ');
          log("📍 Reverse geocoded address: $shopAddress1");
        }
      } catch (geoError) {
        log("⚠️ Reverse geocoding failed (will still update lat/lng): $geoError");
      }

      final Map<String, dynamic> body = {
        "lat": lat,
        "lng": lng,
        if (shopAddress1.isNotEmpty) "shopAddress1": shopAddress1,
      };

      log("📤 updateRetailerLocation body: $body");

      final data = await ApiBaseHelper().postEither(
        endPoint: "${ApiEndPoints.kUpdateRetailerLocation}$retailerId",
        body: body,
        hasBody: true,
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      return data.fold(
            (l) => Left(GlobalErrorModel(error: l.error.toString())),
            (r) => Right(RetailerModel.fromJson(r['data'])),
      );
    } catch (e) {
      log("updateRetailerLocation error: $e");
      return Left(GlobalErrorModel(error: e.toString()));
    }
  }

  @override
  Future<Either<GlobalErrorModel, BanksListModel>> getAllBanks() async {
    try {
      var data = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kGetAllBanks,
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
      );

      return data.fold(
            (l) => Left(GlobalErrorModel(error: l.error.toString())),
            (r) => Right(BanksListModel.fromJson(r)),
      );
    } catch (e) {
      log("getAllBanks error: $e");
      return Left(GlobalErrorModel(error: e.toString()));
    }
  }

  @override
  Future<Either<GlobalErrorModel, RecoveryModel>> addRecovery(AddRecoveryModel model) async {
    try {
      final hasImage = model.imagePath != null && model.imagePath!.isNotEmpty;

      final Map<String, String> body = {
        'bankId': model.bankId,
        'amount': model.amount.toString(),
      };

      if (model.date != null) body['date'] = model.date!;
      if (model.details != null && model.details!.isNotEmpty) body['details'] = model.details!;

      log("Body: $body");

      // ADD THIS LOGGING
      log("=== ADD RECOVERY DEBUG ===");
      log("Retailer ID: ${model.retailerId}");
      log("Request Body: ${json.encode(body)}");
      log("Endpoint: ${ApiEndPoints.kAddRecovery}${model.retailerId}/add");
      log("Has Image: $hasImage");
      if (hasImage) log("Image Path: ${model.imagePath}");
      log("========================");

      var data = await ApiBaseHelper().postMultiPartEither(
        endPoint: "${ApiEndPoints.kAddRecovery}${model.retailerId}/add",
        body: body,
        isRequiredHeader: false,
        hasBody: true,
        hasFile: hasImage,
        path: hasImage ? model.imagePath! : null,
      );

      return data.fold(
            (l) {
          log("❌ ADD RECOVERY ERROR: ${l.error}");
          return Left(GlobalErrorModel(error: l.error.toString()));
        },
            (r) {
          log("✅ ADD RECOVERY SUCCESS: ${json.encode(r)}");
          return Right(RecoveryModel.fromJson(r['data']));
        },
      );
    } catch (e) {
      log("❌ addRecovery exception: $e");
      return Left(GlobalErrorModel(error: e.toString()));
    }
  }
}