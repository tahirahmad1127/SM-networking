import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sm_networking/infrastructure/model/user.dart';
import 'package:uuid/uuid.dart';

import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/error.dart';

abstract class AuthRepository {
  Future<Either<GlobalErrorModel, UserModel>> login({required String identifier, required String password, required bool isPhone,});

  Future<Either<GlobalErrorModel, User>> getUserByID(String userID);

  Future<Either<GlobalErrorModel, void>> logout({required String userId});
}

class AuthRepositoryImp extends AuthRepository {

  // static const String bypass = "?x-vercel-protection-bypass=karyanadevserverkaryanadevserver";
  // static const String bypassAnd = "&x-vercel-protection-bypass=karyanadevserverkaryanadevserver";
  //
  // String _withBypass(String endpoint) {
  //   if (endpoint.contains("?")) {
  //     return "$endpoint$bypassAnd";
  //   }
  //   return "$endpoint$bypass";
  // }

  /// Returns a stable per-install identifier so the backend can enforce
  /// single-device login. Generated once with the uuid package and saved
  /// to SharedPreferences; the same value is reused on every later login
  /// from this install. (device_info_plus no longer exposes a true
  /// hardware ID on Android — androidId/serialNumber were both removed
  /// from recent versions — so a persisted UUID is the reliable option.)
  Future<String> _getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString('device_id');
      if (existing != null && existing.isNotEmpty) return existing;

      final newId = const Uuid().v4();
      await prefs.setString('device_id', newId);
      return newId;
    } catch (e) {
      log('_getDeviceId error: $e');
      return '';
    }
  }

  @override
  Future<Either<GlobalErrorModel, UserModel>> login({required String identifier, required String password, required bool isPhone,}) async {
    final deviceId = await _getDeviceId();
    var data = await ApiBaseHelper().postEither(
        endPoint: ApiEndPoints.kWarehouseManagerLogin,
        isRequiredHeader: true,
        hasBody: true,
        body: isPhone
            ? {
          "phone": identifier,
          "password": password,
          "deviceId": deviceId,
        }
            : {
          "email": identifier.toLowerCase(),
          "password": password,
          "deviceId": deviceId,
        },
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        });
    return data.fold((l) {
      return Left(GlobalErrorModel(error: l.error.toString()));
    }, (r) {
      return Right(UserModel.fromJson(r));
    });
  }

  @override
  Future<Either<GlobalErrorModel, User>> getUserByID(String userID) async {
    var data = await ApiBaseHelper().getEither(
        endPoint: ApiEndPoints.kGetUserByID + userID,
        // endPoint: _withBypass(ApiEndPoints.kGetUserByID + userID),
        isRequiredHeader: true,
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        });
    return data.fold((l) {
      return Left(GlobalErrorModel(error: l.error.toString()));
    }, (r) {
      return Right(User.fromJson(r['data']));
    });
  }

  @override
  Future<Either<GlobalErrorModel, void>> logout({required String userId}) async {
    var data = await ApiBaseHelper().postEither(
        endPoint: ApiEndPoints.kWarehouseManagerLogout,
        isRequiredHeader: true,
        hasBody: true,
        body: {'userId': userId},
        header: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        });
    return data.fold((l) {
      return Left(GlobalErrorModel(error: l.error.toString()));
    }, (r) {
      return const Right(null);
    });
  }
}