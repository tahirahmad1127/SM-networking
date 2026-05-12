import 'dart:developer';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:sm_networking/infrastructure/model/user.dart';

import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/error.dart';

abstract class AuthRepository {
  Future<Either<GlobalErrorModel, UserModel>> login({required String identifier, required String password, required bool isPhone,});

  Future<Either<GlobalErrorModel, User>> getUserByID(String userID);
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

  @override
  Future<Either<GlobalErrorModel, UserModel>> login({required String identifier, required String password, required bool isPhone,}) async {
    var data = await ApiBaseHelper().postEither(
        endPoint: ApiEndPoints.kWarehouseManagerLogin,
        isRequiredHeader: true,
        hasBody: true,
        body: isPhone
            ? {
          "phone": identifier,
          "password": password,
        }
            : {
          "email": identifier,
          "password": password,
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
}
