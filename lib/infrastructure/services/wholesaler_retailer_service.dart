import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:sm_networking/configurations/back_end_configs.dart';
import 'package:sm_networking/infrastructure/api_helper.dart';
import 'package:sm_networking/infrastructure/model/wholesaler_retailer_model.dart';

/// Handles all network calls for wholesalers and retailers.
///
/// Follows the exact same pattern used in [AddDistributorView]:
///   • JSON-only requests  → [ApiBaseHelper.postEither]
///   • Multipart (+ image) → [http.MultipartRequest]  (same as distributor register)
class WholesalerRetailerService {
  final ApiBaseHelper _api = ApiBaseHelper();

  // ── Add ─────────────────────────────────────────────────────────────────────

  Future<WholesalerRetailerModel> addEntry({
    required String endpoint,
    required AddWholesalerRetailerModel model,
    required String token,
    File? imageFile,
  }) async {
    final authHeader = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    if (imageFile != null) {
      // ── Multipart ────────────────────────────────────────────────────────
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${BackendConfigs.apiUrl}$endpoint'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      // Send every scalar field explicitly (no forEach on toJson() so
      // the nested addressFromGoogle map never leaks into fields).
      request.fields['name']     = model.name;
      request.fields['contacts'] = model.contacts;
      request.fields['zone']     = model.zone;
      request.fields['town']     = model.town;
      request.fields['address']  = model.address;

      // Flat lat/lng — covers servers that read these directly.
      request.fields['lat'] = model.lat.toString();
      request.fields['lng'] = model.lng.toString();

      // Bracket notation — covers servers that parse nested objects from
      // multipart fields (e.g. express with extended body parser).
      request.fields['addressFromGoogle[lat]'] = model.lat.toString();
      request.fields['addressFromGoogle[lng]'] = model.lng.toString();

      // ── Image ──────────────────────────────────────────────────────────
      // Field name MUST match the multer field name in your backend route.
      // Currently 'pic' — change to 'image' if the server still returns "".
      final multipartFile =
      await http.MultipartFile.fromPath('pic', imageFile.path);
      request.files.add(multipartFile);

      // Debug log — remove after confirming image uploads correctly.
      debugPrint('📤 [WholesalerService] Multipart fields: ${request.fields}');
      debugPrint('📤 [WholesalerService] File → field:"${multipartFile.field}" '
          'filename:"${multipartFile.filename}" '
          'length:${multipartFile.length}B');

      final streamed  = await request.send();
      final response  = await http.Response.fromStream(streamed);

      debugPrint('📥 [WholesalerService] ${response.statusCode}: ${response.body}');

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = body['data'] as Map<String, dynamic>? ?? body;
        return WholesalerRetailerModel.fromJson(data);
      } else {
        throw Exception(
            body['message'] ?? 'Upload failed (${response.statusCode})');
      }
    } else {
      // ── JSON-only ─────────────────────────────────────────────────────────
      final result = await _api.postEither(
        endPoint: endpoint,
        isRequiredHeader: true,
        hasBody: true,
        body: model.toJson(),
        header: authHeader,
      );

      return result.fold(
            (error) => throw Exception(error.error ?? 'Failed to add entry'),
            (data) {
          final inner = data['data'] as Map<String, dynamic>? ?? data;
          return WholesalerRetailerModel.fromJson(inner);
        },
      );
    }
  }

  // ── Fetch List ───────────────────────────────────────────────────────────────

  Future<List<WholesalerRetailerModel>> fetchEntries({
    required String endpoint,
    required String token,
    String? tsmId,
    String? zoneId,
    String? townId,
    int page = 1,
    int limit = 50,
  }) async {
    String url = endpoint;
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (tsmId != null && tsmId.isNotEmpty) 'tsm': tsmId,
      if (zoneId != null && zoneId.isNotEmpty) 'zone': zoneId,
      if (townId != null && townId.isNotEmpty) 'town': townId,
    };
    final queryString =
    params.entries.map((e) => '${e.key}=${e.value}').join('&');
    url = '$url?$queryString';

    final result = await _api.getEither(
      endPoint: url,
      isRequiredHeader: true,
      header: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return result.fold(
          (error) => throw Exception(error.error ?? 'Failed to fetch entries'),
          (data) {
        final raw = data['data'];
        if (raw is List) {
          return raw
              .whereType<Map>()
              .map((e) => WholesalerRetailerModel.fromJson(
            Map<String, dynamic>.from(e),
          ))
              .toList();
        }
        return [];
      },
    );
  }
}