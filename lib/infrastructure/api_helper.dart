import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

import '../application/connectivity_status.dart';
import '../configurations/back_end_configs.dart';
import 'model/error.dart';

var logger = Logger();

class ApiBaseHelper {
  Future<Either<GlobalErrorModel, dynamic>> getEither({required String endPoint, required bool isRequiredHeader, Map<String, String>? header}) async {
    DateTime executionTime = DateTime.now();
    // ignore: prefer_typing_uninitialized_variables
    Either<GlobalErrorModel, dynamic> responseJson;
    try {
      return await InternetConnectivityHelper.checkConnectivity()
          .then((value) async {
        if (value == true) {
          final response = await http.get(
              Uri.parse(BackendConfigs.apiUrl + endPoint),
              headers: isRequiredHeader ? header! : null);
          responseJson = _returnResponseEither(response);
          logger.i(
              "BaseUrl -> ${BackendConfigs.baseUrl} || EndPoints -> $endPoint || Status Code -> ${response.statusCode.toString()} || Response Time: ${DateTime.now().difference(executionTime).inMilliseconds} ms");
          return responseJson.fold((l) => Left(l), (r) => Right(r));
        } else {
          return Left(GlobalErrorModel(
              error: "Oops! It seems you are not connected to the internet."));
        }
      });
    } on SocketException catch (e) {
      logger.i("Socket Exception");
      logger.e(e.message.toString());
      return Left(GlobalErrorModel(
          error:
          "Some of our servers are undergoing maintenance. If you are currently facing difficulty in connecting, kindly wait a little and retry." +
              "\nSorry for the inconvenience."));
    } on HttpException catch (e) {
      logger.i("HTTP Exception");
      logger.e(e.message.toString());
      return Left(GlobalErrorModel(
          error: "Sorry! We are unable to complete your request.!"));
    } on TimeoutException catch (e) {
      logger.i("TimeOut Exception");
      logger.e(e.message.toString());
      return Left(GlobalErrorModel(
          error: "Sorry! We are unable to connect our servers.!"));
    } catch (e) {
      return Left(GlobalErrorModel(error: e.toString()));
    }
  }

  Future<Either<GlobalErrorModel, dynamic>> postEither({required String endPoint, required bool isRequiredHeader, required bool hasBody, dynamic body, Map<String, String>? header}) async {
    DateTime executionTime = DateTime.now();
    // ignore: prefer_typing_uninitialized_variables
    Either<GlobalErrorModel, dynamic> responseJson;

    try {
      return await InternetConnectivityHelper.checkConnectivity()
          .then((value) async {
        if (value == true) {
          final response = await http.post(
              Uri.parse(BackendConfigs.apiUrl + endPoint),
              headers: isRequiredHeader ? header! : null,
              body: hasBody == true ? jsonEncode(body) : null);

          responseJson = _returnResponseEither(response);
          logger.i(
              "BaseUrl -> ${BackendConfigs.baseUrl} || EndPoints -> $endPoint || Status Code -> ${response.statusCode.toString()} || Reason Phrase -> ${response.reasonPhrase.toString()} || Response Time: ${DateTime.now().difference(executionTime).inMilliseconds} ms");
          return responseJson.fold((l) => Left(l), (r) => Right(r));
        } else {
          return Left(GlobalErrorModel(
              error: "Oops! It seems you are not connected to the internet."));
        }
      });
    } on SocketException catch (e) {
      logger.i("Socket Exception");
      logger.e(e.message.toString());
      return Left(GlobalErrorModel(
          error:
          "Some of our servers are undergoing maintenance. If you are currently facing difficulty in connecting, kindly wait a little and retry." +
              "\nSorry for the inconvenience."));
    } on HttpException catch (e) {
      logger.i("HTTP Exception");
      logger.e(e.message.toString());
      return Left(GlobalErrorModel(
          error: "Sorry! We are unable to complete your request.!"));
    } on TimeoutException catch (e) {
      logger.i("TimeOut Exception");
      logger.e(e.message.toString());
      return Left(GlobalErrorModel(
          error: "Sorry! We are unable to connect our servers.!"));
    } catch (e) {
      return Left(GlobalErrorModel(error: e.toString()));
    }
  }

  Future<Either<GlobalErrorModel, dynamic>> deleteEither({required String endPoint, required bool isRequiredHeader, required bool hasBody, dynamic body, Map<String, String>? header}) async {
    DateTime executionTime = DateTime.now();
    // ignore: prefer_typing_uninitialized_variables
    Either<GlobalErrorModel, dynamic> responseJson;
    try {
      return await InternetConnectivityHelper.checkConnectivity()
          .then((value) async {
        if (value == true) {
          final response = await http.delete(
              Uri.parse(BackendConfigs.apiUrl + endPoint),
              headers: isRequiredHeader ? header! : null,
              body: hasBody == true ? jsonEncode(body) : null);
          responseJson = _returnResponseEither(response);
          logger.i(
              "BaseUrl -> ${BackendConfigs.baseUrl} || EndPoints -> $endPoint || Status Code -> ${response.statusCode.toString()} || Response Time: ${DateTime.now().difference(executionTime).inMilliseconds} ms");
          return responseJson.fold((l) => Left(l), (r) => Right(r));
        } else {
          return Left(GlobalErrorModel(
              error: "Oops! It seems you are not connected to the internet."));
        }
      });
    } on SocketException catch (e) {
      logger.i("Socket Exception");
      logger.e(e.message.toString());
      return Left(GlobalErrorModel(
          error:
          "Some of our servers are undergoing maintenance. If you are currently facing difficulty in connecting, kindly wait a little and retry." +
              "\nSorry for the inconvenience."));
    } on HttpException catch (e) {
      logger.i("HTTP Exception");
      logger.e(e.message.toString());
      return Left(GlobalErrorModel(
          error: "Sorry! We are unable to complete your request.!"));
    } on TimeoutException catch (e) {
      logger.i("TimeOut Exception");
      logger.e(e.message.toString());
      return Left(GlobalErrorModel(
          error: "Sorry! We are unable to connect our servers.!"));
    } catch (e) {
      return Left(GlobalErrorModel(error: "Something went wrong."));
    }
  }

  Future<Either<GlobalErrorModel, dynamic>> postMultiPartEither(
      {required String endPoint,
        required bool isRequiredHeader,
        required bool hasBody,
        String? path,
        required bool hasFile,
        dynamic body,
        Map<String, String>? header}) async {
    log(body.toString());
    DateTime executionTime = DateTime.now();
    // ignore: prefer_typing_uninitialized_variables
    Either<GlobalErrorModel, dynamic> responseJson;
    try {
      return await InternetConnectivityHelper.checkConnectivity()
          .then((value) async {
        if (value == true) {
          var request = http.MultipartRequest(
              'POST', Uri.parse(BackendConfigs.apiUrl + endPoint));

          // FIX: body is dynamic but MultipartRequest.fields requires Map<String, String>.
          // Convert every value to String explicitly so addAll never silently drops fields.
          if (hasBody && body != null) {
            final Map<String, String> stringFields = (body as Map).map(
                  (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
            );
            request.fields.addAll(stringFields);
          }

          // Only add Accept header — do NOT set Content-Type for multipart
          // (http package sets multipart/form-data + boundary automatically)
          if (isRequiredHeader && header != null) {
            final safeHeaders = Map<String, String>.from(header)
              ..remove('Content-Type')
              ..remove('content-type');
            request.headers.addAll(safeHeaders);
          }

          log("📦 Fields being sent: ${request.fields}");
          log("📎 Files being sent: ${request.files.map((f) => f.field).toList()}");

          if (hasFile && path != null) {
            log('Sending file: $path');
            // Use 'receiptPic' as the field name expected by the server
            request.files.add(await http.MultipartFile.fromPath('receiptPic', path));
          }

          http.StreamedResponse streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);

          responseJson = _returnResponseEither(response);

          logger.i(
              "BaseUrl -> ${BackendConfigs.baseUrl} || EndPoints -> $endPoint || Status Code -> ${response.statusCode.toString()} || Status Code -> ${response.reasonPhrase.toString()} || ${DateTime.now()}");

          return responseJson.fold((l) => Left(l), (r) => Right(r));
        } else {
          return Left(GlobalErrorModel(
              error: "Oops! It seems you are not connected to the internet."));
        }
      });
    } on SocketException catch (e) {
      logger.i("Socket Exception");
      logger.e(e.message.toString());
      return Left(GlobalErrorModel(
          error:
          "Some of our servers are undergoing maintenance. If you are currently facing difficulty in connecting, kindly wait a little and retry." +
              "\nSorry for the inconvenience."));
    } on HttpException catch (e) {
      logger.i("HTTP Exception");
      logger.e(e.message.toString());
      return Left(GlobalErrorModel(
          error: "Sorry! We are unable to complete your request.!"));
    } on TimeoutException catch (e) {
      logger.i("TimeOut Exception");
      logger.e(e.message.toString());
      return Left(GlobalErrorModel(
          error: "Sorry! We are unable to connect our servers.!"));
    } catch (e) {
      rethrow;
      return Left(GlobalErrorModel(error: e.toString()));
    }
  }

  Future<Either<GlobalErrorModel, dynamic>> postMultipleImageMultiPartEither(
      {required String endPoint,
        required bool isRequiredHeader,
        required bool hasBody,
        List<String>? path,
        required bool hasFile,
        dynamic body,
        Map<String, String>? header}) async {
    log(body.toString());
    DateTime executionTime = DateTime.now();
    // ignore: prefer_typing_uninitialized_variables
    Either<GlobalErrorModel, dynamic> responseJson;
    try {
      return await InternetConnectivityHelper.checkConnectivity()
          .then((value) async {
        if (value == true) {
          var request = http.MultipartRequest(
              'POST', Uri.parse(BackendConfigs.apiUrl + endPoint));

          // FIX: same cast applied here for consistency
          if (hasBody && body != null) {
            final Map<String, String> stringFields = (body as Map).map(
                  (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
            );
            request.fields.addAll(stringFields);
          }

          request.headers.addAll(header!);
          if (hasFile) {
            request.files
                .add(await http.MultipartFile.fromPath('file', path![0]));
            if (path.length > 1) {
              request.files
                  .add(await http.MultipartFile.fromPath('template', path[1]));
            }
          }
          http.StreamedResponse streamedResponse = await request.send();
          final response = await http.Response.fromStream(streamedResponse);

          responseJson = _returnResponseEither(response);

          logger.i(
              "BaseUrl -> ${BackendConfigs.baseUrl} || EndPoints -> $endPoint || Status Code -> ${response.statusCode.toString()} || Status Code -> ${response.reasonPhrase.toString()} || ${DateTime.now()}");

          return responseJson.fold((l) => Left(l), (r) => Right(r));
        } else {
          return Left(GlobalErrorModel(
              error: "Oops! It seems you are not connected to the internet."));
        }
      });
    } on SocketException catch (e) {
      logger.i("Socket Exception");
      logger.e(e.message.toString());
      return Left(GlobalErrorModel(
          error:
          "Some of our servers are undergoing maintenance. If you are currently facing difficulty in connecting, kindly wait a little and retry." +
              "\nSorry for the inconvenience."));
    } on HttpException catch (e) {
      logger.i("HTTP Exception");
      logger.e(e.message.toString());
      return Left(GlobalErrorModel(
          error: "Sorry! We are unable to complete your request.!"));
    } on TimeoutException catch (e) {
      logger.i("TimeOut Exception");
      logger.e(e.message.toString());
      return Left(GlobalErrorModel(
          error: "Sorry! We are unable to connect our servers.!"));
    } catch (e) {
      rethrow;
      return Left(GlobalErrorModel(error: e.toString()));
    }
  }

  Either<GlobalErrorModel, dynamic> _returnResponseEither(
      http.Response response) {
    log(response.body.toString());
    try {
      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseJson = json.decode(response.body.toString());
        return Right(responseJson);
      } else if (response.statusCode == 400) {
        try {
          var responseJson = json.decode(response.body.toString());
          // Handle validation error shape: {"msg":"Validation failed","errors":[...]}
          if (responseJson is Map && responseJson['msg'] != null) {
            final errors = responseJson['errors'];
            if (errors is List && errors.isNotEmpty) {
              final msgs = errors.map((e) => e['msg'].toString()).join(', ');
              return Left(GlobalErrorModel(error: msgs));
            }
            return Left(GlobalErrorModel(error: responseJson['msg'].toString()));
          }
          var errorModel = GlobalErrorModel.fromJson(responseJson);
          return Left(GlobalErrorModel(error: errorModel.error.toString()));
        } catch (_) {
          return Left(GlobalErrorModel(error: "Bad request."));
        }
      } else if (response.statusCode == 401) {
        return Left(GlobalErrorModel(
            error: "Sorry! You are not allowed to perform this operation.!"));
      } else if (response.statusCode == 404) {
        return Left(
            GlobalErrorModel(error: "Sorry! Your requested data not found!"));
      } else if (response.statusCode == 403) {
        return Left(GlobalErrorModel(error: "UnAuthorized"));
      } else if (response.statusCode == 500) {
        log(response.reasonPhrase.toString());
        return Left(GlobalErrorModel(
            error: "Sorry! We are facing some internal connection issues.!"));
      } else if (response.statusCode == 503) {
        return Left(GlobalErrorModel(
            error: "Sorry! We are facing some issues in connection.!"));
      } else if (response.statusCode == 413) {
        return Left(GlobalErrorModel(
            error:
                "Receipt image is too large for the server. Try a smaller photo or lower camera resolution."));
      } else {
        return Left(GlobalErrorModel(error: "Sorry! Some thing went wrong!."));
      }
    } catch (e) {
      log(e.toString());
      return Left(GlobalErrorModel(error: "Sorry! Some thing went wrong!."));
    }
  }
}