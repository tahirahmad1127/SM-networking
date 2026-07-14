// To parse this JSON data, do
//
//     final categoryListingModel = categoryListingModelFromJson(jsonString);

import 'dart:convert';

CategoryListingModel categoryListingModelFromJson(String str) =>
    CategoryListingModel.fromJson(json.decode(str));

String categoryListingModelToJson(CategoryListingModel data) =>
    json.encode(data.toJson());

class CategoryListingModel {
  final String? msg;
  final List<CategoryModel>? data;

  CategoryListingModel({
    this.msg,
    this.data,
  });

  factory CategoryListingModel.fromJson(Map<String, dynamic> json) =>
      CategoryListingModel(
        msg: json["msg"],
        data: json["data"] == null
            ? []
            : List<CategoryModel>.from(
                (json["data"] as List)
                    .whereType<Map<String, dynamic>>()
                    .map((x) => CategoryModel.fromJson(x)),
              ),
      );

  Map<String, dynamic> toJson() => {
        "msg": msg,
        "data": data == null
            ? []
            : List<dynamic>.from(data!.map((x) => x.toJson())),
      };
}

class CategoryModel {
  final String? id;
  final String? urduName;
  final String? englishName;
  final String? image;
  final CityId? cityId;
  final bool? isDeleted;
  final bool? isActive;
  final bool? adminVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  CategoryModel({
    this.id,
    this.urduName,
    this.englishName,
    this.image,
    this.cityId,
    this.isDeleted,
    this.isActive,
    this.adminVerified,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: json["_id"],
        urduName: json["urduName"],
        englishName: json["englishName"],
        image: json["image"],
        // cityID can be a full object OR just a string ID — handle both safely
        cityId: json["cityID"] == null
            ? null
            : json["cityID"] is Map<String, dynamic>
                ? CityId.fromJson(json["cityID"] as Map<String, dynamic>)
                : CityId(id: json["cityID"].toString()),
        isDeleted: json["isDeleted"],
        isActive: json["isActive"],
        adminVerified: json["adminVerified"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.parse(json["createdAt"]),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.parse(json["updatedAt"]),
        v: json["__v"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "urduName": urduName,
        "englishName": englishName,
        "image": image,
        "cityID": cityId?.toJson(),
        "isDeleted": isDeleted,
        "isActive": isActive,
        "adminVerified": adminVerified,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
        "__v": v,
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
