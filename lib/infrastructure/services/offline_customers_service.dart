import 'dart:developer';

import 'package:dartz/dartz.dart';

import '../../configurations/end_points.dart';
import '../api_helper.dart';
import '../model/error.dart';
import '../model/user.dart';
import 'auth_token_helper.dart';

/// GET offline/distributors, offline/retailers, offline/wholesalers — bulk
/// customer lists for Offline Mode. Flat response shape ({success, count,
/// data: [{id, name, contacts, address, type, location:{lat,lng},
/// zone:{id,name}, town:{id,name}, isActive, isAdminVerified}]}), much
/// smaller than the online Distributor/Wholesaler shapes. Rather than a new
/// model, each entry is mapped straight into the existing Distributor /
/// Wholesaler classes (via their constructors, not fromJson — the flat
/// shape's field names/keys don't match those classes' fromJson) so the
/// already-built cache storage (OfflineCacheService) and card UI
/// (retailers_view.dart) work unchanged.
class OfflineCustomersService {
  Map<String, String> _headers(String? token) {
    final rawToken = (token ?? '').startsWith('Bearer ')
        ? token!.substring(7)
        : (token ?? '');
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (rawToken.isNotEmpty) 'x-auth-token': rawToken,
      if (rawToken.isNotEmpty) 'Authorization': 'Bearer $rawToken',
    };
  }

  DistributorRef? _ref(dynamic json) {
    if (json == null || json is! Map) return null;
    return DistributorRef(
      id: json['id']?.toString(),
      name: json['name']?.toString(),
    );
  }

  DistributorLocation? _location(dynamic json) {
    if (json == null || json is! Map) return null;
    final lat = json['lat'];
    final lng = json['lng'];
    return DistributorLocation(
      lat: lat == null ? null : (lat as num).toDouble(),
      lng: lng == null ? null : (lng as num).toDouble(),
    );
  }

  Wholesaler _toWholesaler(Map<String, dynamic> json) => Wholesaler(
        id: json['id']?.toString(),
        name: json['name']?.toString(),
        contacts: json['contacts']?.toString(),
        address: json['address']?.toString(),
        zone: _ref(json['zone']),
        town: _ref(json['town']),
        isActive: json['isActive'] as bool?,
        isAdminVerified: json['isAdminVerified'] as bool?,
        shopLocation: _location(json['location']),
      );

  Distributor _toDistributor(Map<String, dynamic> json) => Distributor(
        id: json['id']?.toString(),
        name: json['name']?.toString(),
        distributionName: json['name']?.toString(),
        phone: json['contacts']?.toString(),
        address: json['address']?.toString(),
        zone: _ref(json['zone']),
        town: _ref(json['town']),
        isActive: json['isActive'] as bool?,
        isAdminVerified: json['isAdminVerified'] as bool?,
        shopLocation: _location(json['location']),
      );

  Future<Either<GlobalErrorModel, List<dynamic>>> _fetchRaw(
      String endPoint) async {
    final token = await getAuthToken();
    final data = await ApiBaseHelper().getEither(
      endPoint: endPoint,
      isRequiredHeader: true,
      header: _headers(token),
    );
    return data.fold(
      (l) {
        log('OfflineCustomersService[$endPoint] FAILED: ${l.error}');
        return Left(GlobalErrorModel(error: l.error.toString()));
      },
      (r) {
        final raw = (r['data'] ?? r['products']) as List<dynamic>? ?? [];
        log('OfflineCustomersService[$endPoint]: received ${raw.length} record(s)');
        return Right(raw);
      },
    );
  }

  Future<Either<GlobalErrorModel, List<Wholesaler>>>
      getAllWholesalersOffline() async {
    final result = await _fetchRaw(ApiEndPoints.kOfflineWholesalers);
    return result.fold(
      (l) => Left(l),
      (raw) => Right(raw
          .map((e) => _toWholesaler(e as Map<String, dynamic>))
          .toList()),
    );
  }

  Future<Either<GlobalErrorModel, List<Wholesaler>>>
      getAllRetailersOffline() async {
    final result = await _fetchRaw(ApiEndPoints.kOfflineRetailers);
    return result.fold(
      (l) => Left(l),
      (raw) => Right(raw
          .map((e) => _toWholesaler(e as Map<String, dynamic>))
          .toList()),
    );
  }

  Future<Either<GlobalErrorModel, List<Distributor>>>
      getAllDistributorsOffline() async {
    final result = await _fetchRaw(ApiEndPoints.kOfflineDistributors);
    return result.fold(
      (l) => Left(l),
      (raw) => Right(raw
          .map((e) => _toDistributor(e as Map<String, dynamic>))
          .toList()),
    );
  }
}
