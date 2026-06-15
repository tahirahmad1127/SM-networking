import 'dart:convert';
import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;

import '../model/site_visit.dart';


class SiteVisitFailure {
  final String error;
  const SiteVisitFailure(this.error);
}

class SiteVisitService {
  static const String _baseUrl = 'https://sm-api-iota.vercel.app/api/';

  /// POST /api/site-visit/add
  Future<Either<SiteVisitFailure, SiteVisitModel>> markAttendance({
    required SiteVisitRequest request,
    required String token,
  }) async {
    final uri = Uri.parse('${_baseUrl}site-visit/add');

    log('📋 SiteVisitService → POST $uri');
    log('📋 Payload: ${jsonEncode(request.toJson())}');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      log('📋 SiteVisit response [${response.statusCode}]: ${response.body}');

      if (response.body.isEmpty) {
        return const Left(SiteVisitFailure('Empty response from server.'));
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = decoded['data'] as Map<String, dynamic>?;
        if (data == null) {
          return const Left(SiteVisitFailure('Invalid response from server.'));
        }
        return Right(SiteVisitModel.fromJson(data));
      } else {
        final msg = decoded['message'] ??
            decoded['msg'] ??
            'Something went wrong (${response.statusCode})';
        return Left(SiteVisitFailure(msg.toString()));
      }
    } catch (e) {
      log('❌ SiteVisitService error: $e');
      return Left(SiteVisitFailure(e.toString()));
    }
  }
}