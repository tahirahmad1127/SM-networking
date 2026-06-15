import 'dart:developer';
import 'package:dartz/dartz.dart';
import 'package:sm_networking/configurations/end_points.dart';
import 'package:sm_networking/infrastructure/api_helper.dart';
import 'package:sm_networking/infrastructure/model/error.dart';
import 'package:sm_networking/infrastructure/model/visit.dart';

/// Abstract definition for visit-related API calls.
abstract class VisitRepository {
  Future<Either<GlobalErrorModel, VisitModel>> addVisit(VisitModel visit);
}

/// Implementation of VisitRepository
class VisitRepositoryImp extends VisitRepository {
  final ApiBaseHelper _apiHelper = ApiBaseHelper();

  @override
  Future<Either<GlobalErrorModel, VisitModel>> addVisit(VisitModel visit) async {
    try {
      final hasFile = visit.image != null && visit.image!.isNotEmpty;

      final Map<String, String> body = {
        'retailerID': visit.retailerId.toString(),
        'salesPersonID': visit.salesPersonId.toString(),
        'shopName': visit.shopName ?? '',
        'retailerEmail': visit.retailerEmail ?? '',
        'retailerImage': visit.retailerImage ?? '',
        'startTime': visit.startTime.toString(),
        'endTime': visit.endTime.toString(),
        'date': visit.date.toString(),
      };

      log("🟢 Sending Add Visit Request: $body");
      if (hasFile) log("📷 Image path: ${visit.image}");

      final data = await _apiHelper.postMultiPartEither(
        endPoint: ApiEndPoints.kAddVisit,
        body: body,
        isRequiredHeader: true,
        header: {'Accept': 'application/json',},
        hasBody: true,
        hasFile: hasFile,
        path: hasFile ? visit.image! : null,
      );

      return data.fold(
            (l) => Left(GlobalErrorModel(error: l.error)),
            (r) {
          final parsed = r['data'];
          log("✅ Visit Added Successfully: $parsed");
          return Right(VisitModel.fromJson(parsed));
        },
      );
    } catch (e) {
      log("❌ Add Visit Error: $e");
      rethrow;
    }
  }
}