import 'dart:convert';

AllBrandsListingModel allBrandsListingModelFromJson(String str) =>
    AllBrandsListingModel.fromJson(json.decode(str));

class AllBrandsListingModel {
  final String? msg;
  final List<AllBrandModel>? data;

  AllBrandsListingModel({this.msg, this.data});

  factory AllBrandsListingModel.fromJson(Map<String, dynamic> json) =>
      AllBrandsListingModel(
        msg: json["msg"],
        data: json["data"] == null
            ? []
            : List<AllBrandModel>.from(
            json["data"]!.map((x) => AllBrandModel.fromJson(x))),
      );
}

class AllBrandModel {
  final String? id;
  final String? brandId;
  final String? englishName;
  final String? category;
  final bool? isDeleted;
  final bool? isActive;
  final bool? adminVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AllBrandModel({
    this.id,
    this.brandId,
    this.englishName,
    this.category,
    this.isDeleted,
    this.isActive,
    this.adminVerified,
    this.createdAt,
    this.updatedAt,
  });

  factory AllBrandModel.fromJson(Map<String, dynamic> json) => AllBrandModel(
    id: json["_id"]?.toString(),
    brandId: json["brandId"]?.toString(),
    englishName: json["englishName"],
    category: json["category"]?.toString(),
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