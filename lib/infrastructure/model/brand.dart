// To parse this JSON data, do
//
//     final brandListingModel = brandListingModelFromJson(jsonString);

import 'dart:convert';

BrandListingModel brandListingModelFromJson(String str) => BrandListingModel.fromJson(json.decode(str));

String brandListingModelToJson(BrandListingModel data) => json.encode(data.toJson());

class BrandListingModel {
  final String? msg;
  final List<BrandModel>? data;

  BrandListingModel({
    this.msg,
    this.data,
  });

  factory BrandListingModel.fromJson(Map<String, dynamic> json) => BrandListingModel(
    msg: json["msg"],
    data: json["data"] == null ? [] : List<BrandModel>.from(json["data"]!.map((x) => BrandModel.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "msg": msg,
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class BrandModel {
  final String? id;
  final String? urduName;
  final String? englishName;
  final int? comission;
  final String? image;
  final CityId? cityId;
  final CategoryId? categoryId;
  final bool? isDeleted;
  final bool? isActive;
  final bool? adminVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  BrandModel({
    this.id,
    this.urduName,
    this.englishName,
    this.comission,
    this.image,
    this.cityId,
    this.categoryId,
    this.isDeleted,
    this.isActive,
    this.adminVerified,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) => BrandModel(
    id: json["_id"]?.toString().trim(),
    urduName: json["urduName"],
    englishName: json["englishName"],
    comission: json["comission"],
    image: json["image"],
    cityId: json["cityID"] == null ? null : CityId.fromJson(json["cityID"]),
    categoryId: json["categoryID"] == null ? null : CategoryId.fromJson(json["categoryID"]),
    isDeleted: json["isDeleted"],
    isActive: json["isActive"],
    adminVerified: json["adminVerified"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    v: json["__v"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "urduName": urduName,
    "englishName": englishName,
    "comission": comission,
    "image": image,
    "cityID": cityId?.toJson(),
    "categoryID": categoryId?.toJson(),
    "isDeleted": isDeleted,
    "isActive": isActive,
    "adminVerified": adminVerified,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
  };
}

class CategoryId {
  final String? id;
  final String? urduName;
  final String? englishName;
  final String? image;

  CategoryId({
    this.id,
    this.urduName,
    this.englishName,
    this.image,
  });

  factory CategoryId.fromJson(Map<String, dynamic> json) => CategoryId(
    id: json["_id"],
    urduName: json["urduName"],
    englishName: json["englishName"],
    image: json["image"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "urduName": urduName,
    "englishName": englishName,
    "image": image,
  };
}

class CityId {
  final String? id;
  final String? name;

  CityId({
    this.id,
    this.name,
  });

  factory CityId.fromJson(Map<String, dynamic> json) => CityId(
    id: json["_id"],
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
  };
}
