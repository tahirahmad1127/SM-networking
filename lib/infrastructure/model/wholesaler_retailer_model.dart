// To parse this JSON data, do
//
//     final model = wholesalerRetailerModelFromJson(jsonString);

import 'dart:convert';

// ─── Helpers (same pattern as add_recovery.dart) ──────────────────────────────

String _refId(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  if (v is Map) return v['_id']?.toString() ?? v['id']?.toString() ?? '';
  return '';
}

String _refName(dynamic v) {
  if (v is Map) return v['name']?.toString() ?? '';
  return '';
}

// ─── AddWholesalerRetailerModel (Request) ─────────────────────────────────────

AddWholesalerRetailerModel addWholesalerRetailerModelFromJson(String str) =>
    AddWholesalerRetailerModel.fromJson(json.decode(str));

String addWholesalerRetailerModelToJson(AddWholesalerRetailerModel data) =>
    json.encode(data.toJson());

class AddWholesalerRetailerModel {
  /// Shop / business name
  final String name;

  /// Phone / WhatsApp contact
  final String contacts;

  /// Zone ObjectId
  final String zone;

  /// Town ObjectId
  final String town;

  /// Street address
  final String address;

  /// Lat picked from Google Maps
  final double lat;

  /// Lng picked from Google Maps
  final double lng;

  /// Optional: base-64 string or remote URL after upload
  final String? pic;

  AddWholesalerRetailerModel({
    required this.name,
    required this.contacts,
    required this.zone,
    required this.town,
    required this.address,
    required this.lat,
    required this.lng,
    this.pic,
  });

  factory AddWholesalerRetailerModel.fromJson(Map<String, dynamic> json) =>
      AddWholesalerRetailerModel(
        name: json['name'] ?? '',
        contacts: json['contacts'] ?? '',
        zone: _refId(json['zone']),
        town: _refId(json['town']),
        address: json['address'] ?? '',
        lat: (json['addressFromGoogle']?['lat'] ?? json['lat'] ?? 0).toDouble(),
        lng: (json['addressFromGoogle']?['lng'] ?? json['lng'] ?? 0).toDouble(),
        pic: json['pic'],
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'contacts': contacts,
    'zone': zone,
    'town': town,
    'address': address,
    'addressFromGoogle': {
      'lat': lat,
      'lng': lng,
    },
    if (pic != null && pic!.isNotEmpty) 'pic': pic,
  };
}

// ─── WholesalerRetailerModel (Response) ───────────────────────────────────────

WholesalerRetailerModel wholesalerRetailerModelFromJson(String str) =>
    WholesalerRetailerModel.fromJson(json.decode(str));

String wholesalerRetailerModelToJson(WholesalerRetailerModel data) =>
    json.encode(data.toJson());

class WholesalerRetailerModel {
  final String id;
  final String name;
  final String contacts;
  final String zone;
  final String zoneName;
  final String town;
  final String townName;
  final String address;
  final double lat;
  final double lng;
  final String? pic;
  final bool isDeleted;
  final String? createdAt;
  final String? updatedAt;

  WholesalerRetailerModel({
    required this.id,
    required this.name,
    required this.contacts,
    required this.zone,
    required this.zoneName,
    required this.town,
    required this.townName,
    required this.address,
    required this.lat,
    required this.lng,
    this.pic,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });

  factory WholesalerRetailerModel.fromJson(Map<String, dynamic> json) {
    final geo = json['addressFromGoogle'];
    return WholesalerRetailerModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      contacts: json['contacts'] ?? '',
      zone: _refId(json['zone']),
      zoneName: (json['zoneName'] ?? _refName(json['zone'])).toString(),
      town: _refId(json['town']),
      townName: (json['townName'] ?? _refName(json['town'])).toString(),
      address: json['address'] ?? '',
      lat: (geo is Map ? geo['lat'] : json['lat'] ?? 0).toDouble(),
      lng: (geo is Map ? geo['lng'] : json['lng'] ?? 0).toDouble(),
      pic: json['pic'],
      isDeleted: json['isDeleted'] ?? false,
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'contacts': contacts,
    'zone': zone,
    'zoneName': zoneName,
    'town': town,
    'townName': townName,
    'address': address,
    'addressFromGoogle': {'lat': lat, 'lng': lng},
    'pic': pic,
    'isDeleted': isDeleted,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}

// ─── WholesalerRetailerListingModel (Paginated response) ─────────────────────

class WholesalerRetailerListingModel {
  final List<WholesalerRetailerModel> data;
  final int total;
  final int page;
  final int totalPages;

  WholesalerRetailerListingModel({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory WholesalerRetailerListingModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v, [int def = 0]) {
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? def;
    }

    final raw = json['data'];
    final list = <WholesalerRetailerModel>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          list.add(WholesalerRetailerModel.fromJson(e));
        } else if (e is Map) {
          list.add(WholesalerRetailerModel.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    return WholesalerRetailerListingModel(
      data: list,
      total: toInt(json['total']),
      page: toInt(json['page'], 1),
      totalPages: toInt(json['totalPages'], 1),
    );
  }
}