import 'dart:developer';
import 'package:dartz/dartz.dart';
import 'package:sm_networking/configurations/end_points.dart';
import 'package:sm_networking/infrastructure/api_helper.dart';
import 'package:sm_networking/infrastructure/model/attendance.dart';
import 'package:sm_networking/infrastructure/model/error.dart';

abstract class AttendanceRepository {
  Future<Either<GlobalErrorModel, AttendanceModel>> checkIn(Map<String, dynamic> body);
  Future<Either<GlobalErrorModel, AttendanceModel>> checkOut(String attendanceId, Map<String, dynamic> body);
}

class AttendanceRepositoryImp extends AttendanceRepository {

  final ApiBaseHelper _apiHelper = ApiBaseHelper();

  @override
  Future<Either<GlobalErrorModel, AttendanceModel>> checkIn(Map<String, dynamic> body) async {
    log("🟢 Sending Check-In Request: $body");

    final data = await _apiHelper.postEither(
      endPoint: ApiEndPoints.kCheckIn,
      isRequiredHeader: true,
      hasBody: true,
      body: body,
      header: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    return data.fold(
          (l) => Left(GlobalErrorModel(error: l.error)),
          (r) {
        final parsed = r['data'];
        return Right(AttendanceModel.fromJson(parsed));
      },
    );
  }

  @override
  Future<Either<GlobalErrorModel, AttendanceModel>> checkOut(String attendanceId, Map<String, dynamic> body) async {
    log("🔵 Sending Check-Out Request for ID: $attendanceId");
    // log("Payload: $body");

    final data = await _apiHelper.postEither(
      endPoint: "${ApiEndPoints.kCheckOut}/$attendanceId",
      isRequiredHeader: true,
      hasBody: true,
      body: body,
      header: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    return data.fold(
          (l) => Left(GlobalErrorModel(error: l.error)),
          (r) {
        final parsed = r['data'];
        return Right(AttendanceModel.fromJson(parsed));
      },
    );
  }
}

