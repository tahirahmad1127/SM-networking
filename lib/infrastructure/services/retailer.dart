import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:sm_networking/infrastructure/model/add_retailer.dart';
import 'package:sm_networking/infrastructure/model/retailer.dart';

import '../../configurations/back_end_configs.dart';
import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/add_recovery.dart';
import '../model/banks.dart';
import '../model/error.dart';

abstract class RetailerRepository {
  Future<Either<GlobalErrorModel, RetailersListingModel>> getRetailers(
      String cityID);

  Future<Either<GlobalErrorModel, RetailerModel>> addRetailer(
      AddRetailerModel model);

  Future<Either<GlobalErrorModel, RetailerModel>> updateRetailerLocation({
    required String retailerId,
    required double lat,
    required double lng,
    required String token,
  });

  Future<Either<GlobalErrorModel, void>> updateDistributorLocation({
    required String distributorId,
    required double lat,
    required double lng,
    required String token,
  });

  Future<Either<GlobalErrorModel, BanksListModel>> getAllBanks();

  Future<Either<GlobalErrorModel, RecoveryListingModel>> getMyPayments(
      String token);

  Future<Either<GlobalErrorModel, RecoveryModel>> addRecovery(
      AddRecoveryModel model, String token);
}

class RetailerRepositoryImp extends RetailerRepository {
  // ─────────────────────────────────────────────────────────────────────────
  // Get Retailers
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<Either<GlobalErrorModel, RetailersListingModel>> getRetailers(
      String cityID) async {
    var data = await ApiBaseHelper().getEither(
      endPoint: "${ApiEndPoints.kGetRetailers}$cityID?page=1&limit=10000",
      isRequiredHeader: true,
      header: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    return data.fold(
          (l) => Left(GlobalErrorModel(error: l.error.toString())),
          (r) => Right(RetailersListingModel.fromJson(r)),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Add Retailer
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<Either<GlobalErrorModel, RetailerModel>> addRetailer(
      AddRetailerModel model) async {
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
        'cityID': model.cityId.toString(),
      };
      if (hasCnic) body['cnic'] = model.cnic!;

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

      return data.fold(
            (l) => Left(GlobalErrorModel(error: l.error.toString())),
            (r) => Right(RetailerModel.fromJson(r['data'])),
      );
    } catch (e) {
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Update Retailer Location
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<Either<GlobalErrorModel, RetailerModel>> updateRetailerLocation({
    required String retailerId,
    required double lat,
    required double lng,
    required String token,
  }) async {
    try {
      String shopAddress1 = '';
      try {
        final placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.name,
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
          ].where((s) => s != null && s.isNotEmpty).toList();
          shopAddress1 = parts.join(', ');
        }
      } catch (geoError) {
        log("⚠️ Reverse geocoding failed: $geoError");
      }

      final data = await ApiBaseHelper().postEither(
        endPoint: "${ApiEndPoints.kUpdateRetailerLocation}$retailerId",
        body: {
          "lat": lat,
          "lng": lng,
          if (shopAddress1.isNotEmpty) "shopAddress1": shopAddress1,
        },
        hasBody: true,
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'x-auth-token': token,
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

  // ─────────────────────────────────────────────────────────────────────────
  // Update Distributor Location
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<Either<GlobalErrorModel, void>> updateDistributorLocation({
    required String distributorId,
    required double lat,
    required double lng,
    required String token,
  }) async {
    try {
      final data = await ApiBaseHelper().postEither(
        endPoint:
        "${ApiEndPoints.kUpdateDistributorLocation}$distributorId",
        body: {"lat": lat, "lng": lng},
        hasBody: true,
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );
      return data.fold(
            (l) => Left(GlobalErrorModel(error: l.error.toString())),
            (r) => const Right(null),
      );
    } catch (e) {
      log("updateDistributorLocation error: $e");
      return Left(GlobalErrorModel(error: e.toString()));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Get All Banks
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<Either<GlobalErrorModel, BanksListModel>> getAllBanks() async {
    try {
      var data = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kGetAllBanks,
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
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

  // ─────────────────────────────────────────────────────────────────────────
  // Get My Payments
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<Either<GlobalErrorModel, RecoveryListingModel>> getMyPayments(
      String token) async {
    try {
      var data = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kGetMyPayments,
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );
      return data.fold(
            (l) => Left(GlobalErrorModel(error: l.error.toString())),
            (r) => Right(RecoveryListingModel.fromJson(r)),
      );
    } catch (e) {
      log("getMyPayments error: $e");
      return Left(GlobalErrorModel(error: e.toString()));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Add Recovery (Payment)
  //
  // Uses http.post DIRECTLY instead of ApiBaseHelper.postEither.
  // Reason: ApiBaseHelper passes headers as Map<String,String> to http.post,
  // but the underlying http package can silently fail to merge headers when
  // the body encoding changes the request internals. By calling http.post
  // directly here, x-auth-token is set explicitly as required by this API.
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Future<Either<GlobalErrorModel, RecoveryModel>> addRecovery(
      AddRecoveryModel model, String token) async {
    try {
      // Strip any accidental "Bearer " prefix already stored in the token
      final rawToken =
      token.startsWith('Bearer ') ? token.substring(7) : token;

      final uri =
      Uri.parse('${BackendConfigs.apiUrl}${ApiEndPoints.kAddRecovery}');

      log("📤 POST → $uri");
      log("📤 Token prefix: ${rawToken.length > 20 ? rawToken.substring(0, 20) : rawToken}...");

      // ── Compress image first so we know its size ─────────────────────
      Uint8List? receiptBytes;
      final picPath = model.receiptPic;
      if (picPath != null && picPath.isNotEmpty) {
        receiptBytes = await _receiptBytesForUpload(picPath);
        log("📎 Receipt compressed: ${receiptBytes.length} bytes "
            "(base64 ≈ ${(receiptBytes.length * 4 / 3).round()} chars)");
      }

      // ── JSON body ─────────────────────────────────────────────────────
      // The API uses express-validator on req.body (JSON), so we must send
      // Content-Type: application/json. The image is base64-encoded inside
      // the body — Vercel's limit is ~4.5 MB and our compressed image is
      // well under 200 KB (~267 KB base64), so this is safe.
      final Map<String, dynamic> jsonBody = {
        'distributionName': model.distributionName,
        'zone': model.zone,
        'town': model.town,
        'tsm': model.tsm,
        'recordedBy': model.recordedBy,
        'amount': model.amount,
        'bankName': model.bankName,
        'branchCode': model.branchCode,
        'paymentMode': model.paymentMode,
        'beneficiaryAccountNumber': model.beneficiaryAccountNumber,
        'beneficiaryAccountName': model.beneficiaryAccountName,
        'beneficiaryBankName': model.beneficiaryBankName,
        if (model.date != null) 'date': model.date,
        if (receiptBytes != null) 'receiptPic': base64Encode(receiptBytes),
      };

      final encodedBody = jsonEncode(jsonBody);
      log("📤 Body keys: ${jsonBody.keys.toList()}");
      log("📤 Total body size: ${encodedBody.length} bytes (${(encodedBody.length / 1024).toStringAsFixed(1)} KB)");

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'x-auth-token': rawToken,
        },
        body: encodedBody,
      );


      log("📥 Status: ${response.statusCode}");
      log("📥 Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        log("✅ Payment created → srNo: ${decoded['data']?['srNo']}");
        return Right(RecoveryModel.fromJson(
            decoded['data'] as Map<String, dynamic>));
      }

      // ── Error handling ─────────────────────────────────────────────────
      String errorMsg;
      switch (response.statusCode) {
        case 401:
          log("❌ 401 — token rejected by server");
          errorMsg = "Session expired. Please log in again.";
          break;
        case 413:
          errorMsg = "Receipt image is too large. Please use a smaller photo.";
          break;
        default:
          errorMsg = "Payment failed. Please try again.";
          try {
            final decoded = jsonDecode(response.body);
            if (decoded['msg'] != null) {
              errorMsg = decoded['msg'].toString();
            }
          } catch (_) {}
      }
      log("❌ addRecovery ${response.statusCode}: $errorMsg");
      return Left(GlobalErrorModel(error: errorMsg));
    } catch (e) {
      log("❌ addRecovery exception: $e");
      return Left(GlobalErrorModel(error: e.toString()));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Image compression helper
  //
  // Camera images can be 8–15 MB. We compress in progressive steps, each
  // time capping the longest side via minWidth/minHeight (flutter_image_compress
  // treats these as the target dimension for the longer side when keepExif is
  // false). Target is 200 KB raw — base64 inflates by ~33% to ~267 KB, which
  // is safely under any server limit.
  //
  // IMPORTANT: we never fall back to raw bytes. If all steps fail we return
  // the smallest result we managed to produce.
  // ─────────────────────────────────────────────────────────────────────────
  static Future<Uint8List> _receiptBytesForUpload(String picPath) async {
    const int targetBytes = 50000; // 50 KB raw → ~67 KB base64 (safe under tight Vercel limits)

    Future<Uint8List?> compress(int maxSide, int quality) =>
        FlutterImageCompress.compressWithFile(
          picPath,
          minWidth: maxSide,
          minHeight: maxSide,
          quality: quality,
          keepExif: false,
          format: CompressFormat.jpeg,
        );

    Uint8List? smallest;

    // Try progressively harder compression until we hit the target.
    // Steps go from decent quality down to thumbnail — receipt text
    // is still readable at 320px / q15.
    for (final step in <List<int>>[
      [1024, 50],
      [800,  40],
      [640,  30],
      [480,  20],
      [320,  15],
    ]) {
      final result = await compress(step[0], step[1]);
      if (result != null && result.isNotEmpty) {
        log("🗜️ step ${step[0]}px q${step[1]} → ${result.length} bytes "
            "(base64 ≈ ${(result.length * 4 / 3).round()} bytes)");
        // Track the smallest we've produced so far
        if (smallest == null || result.length < smallest.length) {
          smallest = result;
        }
        if (result.length <= targetBytes) {
          log("✅ Under target at ${step[0]}px q${step[1]}");
          return result;
        }
      }
    }

    // Return the smallest compressed result — never send raw camera bytes.
    if (smallest != null) {
      log("⚠️ Could not reach ${targetBytes}B target; "
          "sending smallest result: ${smallest.length} bytes");
      return smallest;
    }

    // True last resort: should never happen, but guard anyway.
    log("❌ All compression steps failed — reading raw file (may be large)");
    return File(picPath).readAsBytes();
  }
}