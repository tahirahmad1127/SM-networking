import 'dart:convert';

class BrandCategoryListingModel {
  final String? msg;
  final List<BrandCategoryModel>? data;

  BrandCategoryListingModel({this.msg, this.data});

  factory BrandCategoryListingModel.fromJson(Map<String, dynamic> json) =>
      BrandCategoryListingModel(
        msg: json["msg"],
        data: json["data"] == null
            ? []
            : List<BrandCategoryModel>.from(
            json["data"]!.map((x) => BrandCategoryModel.fromJson(x))),
      );
}

class BrandCategoryModel {
  final String? id;
  final String? urduName;
  final String? englishName;
  final String? categoryId;
  final BrandRef? brand;
  /// All brand IDs this category belongs to (new backend format).
  final List<String> brandIds;
  final bool? isDeleted;
  final bool? isActive;
  final bool? adminVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BrandCategoryModel({
    this.id,
    this.urduName,
    this.englishName,
    this.categoryId,
    this.brand,
    this.brandIds = const [],
    this.isDeleted,
    this.isActive,
    this.adminVerified,
    this.createdAt,
    this.updatedAt,
  });

  /// "brand" can now be:
  ///   - a List<dynamic> of brand ID strings  ← new backend format
  ///   - a plain String (single brand ID)
  ///   - a Map { "_id": ..., "englishName": ... }
  /// We only need one ID for filtering so we take the first element.
  /// Extracts all brand IDs from the brand field (handles String, List, Map).
  static List<String> _parseBrandIds(dynamic value) {
    if (value == null) return [];
    if (value is String) return [value];
    if (value is Map) {
      final id = value['_id']?.toString() ?? value['id']?.toString();
      return id != null ? [id] : [];
    }
    if (value is List) {
      return value.map((e) {
        if (e is String) return e;
        if (e is Map) return e['_id']?.toString() ?? e['id']?.toString() ?? '';
        return '';
      }).where((s) => s.isNotEmpty).toList();
    }
    return [];
  }

  static BrandRef? _parseBrandRef(dynamic value) {
    if (value == null) return null;
    if (value is String) return BrandRef(id: value);
    if (value is Map<String, dynamic>) return BrandRef.fromJson(value);
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is String) return BrandRef(id: first);
      if (first is Map<String, dynamic>) return BrandRef.fromJson(first);
    }
    return null;
  }

  factory BrandCategoryModel.fromJson(Map<String, dynamic> json) =>
      BrandCategoryModel(
        id: json["_id"]?.toString(),
        urduName: json["urduName"],
        englishName: json["englishName"],
        categoryId: json["categoryId"]?.toString(),
        brand: _parseBrandRef(json["brand"]),
        brandIds: _parseBrandIds(json["brand"]),
        isDeleted: json["isDeleted"],
        isActive: json["isActive"],
        adminVerified: json["adminVerified"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.parse(json["updatedAt"]),
      );
}

class BrandRef {
  final String? id;
  final String? englishName;

  BrandRef({this.id, this.englishName});

  factory BrandRef.fromJson(Map<String, dynamic> json) => BrandRef(
    id: json["_id"]?.toString(),
    englishName: json["englishName"],
  );
}