// To parse this JSON data, do
//
//     final siteVisitModel = siteVisitModelFromJson(jsonString);

import 'dart:convert';

SiteVisitModel siteVisitModelFromJson(String str) =>
    SiteVisitModel.fromJson(json.decode(str));

String siteVisitModelToJson(SiteVisitModel data) =>
    json.encode(data.toJson());

class SiteVisitModel {
  final String? salesPersonID;
  final String? retailerID;
  final String? shopName;
  final String? retailerEmail;
  final String? retailerImage;
  final String? date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? image;
  final bool? isDeleted;
  final String? id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  SiteVisitModel({
    this.salesPersonID,
    this.retailerID,
    this.shopName,
    this.retailerEmail,
    this.retailerImage,
    this.date,
    this.checkIn,
    this.checkOut,
    this.image,
    this.isDeleted,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory SiteVisitModel.fromJson(Map<String, dynamic> json) => SiteVisitModel(
    salesPersonID: json["salesPersonID"],
    retailerID: json["retailerID"],
    shopName: json["shopName"],
    retailerEmail: json["retailerEmail"],
    retailerImage: json["retailerImage"],
    date: json["date"],
    checkIn: json["checkIn"] == null
        ? null
        : DateTime.parse(json["checkIn"]),
    checkOut: json["checkOut"] == null
        ? null
        : DateTime.parse(json["checkOut"]),
    image: json["image"],
    isDeleted: json["isDeleted"],
    id: json["_id"],
    createdAt: json["createdAt"] == null
        ? null
        : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null
        ? null
        : DateTime.parse(json["updatedAt"]),
    v: json["__v"],
  );

  Map<String, dynamic> toJson() => {
    "salesPersonID": salesPersonID,
    "retailerID": retailerID,
    "shopName": shopName,
    "retailerEmail": retailerEmail,
    "retailerImage": retailerImage,
    "date": date,
    "checkIn": checkIn?.toIso8601String(),
    "checkOut": checkOut?.toIso8601String(),
    "image": image,
    "isDeleted": isDeleted,
    "_id": id,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
  };
}

// ─── Request payload sent to POST /api/site-visit/add ────────────────────────

class SiteVisitRequest {
  final String salesPersonID;
  final String retailerID;
  final String shopName;
  final String retailerEmail;
  final String retailerImage;
  final String date;
  final String checkIn;
  final String checkOut;
  final String image;

  SiteVisitRequest({
    required this.salesPersonID,
    required this.retailerID,
    required this.shopName,
    required this.retailerEmail,
    required this.retailerImage,
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.image,
  });

  Map<String, dynamic> toJson() => {
    "salesPersonID": salesPersonID,
    "retailerID": retailerID,
    "shopName": shopName,
    "retailerEmail": retailerEmail,
    "retailerImage": retailerImage,
    "date": date,
    "checkIn": checkIn,
    "checkOut": checkOut,
    "image": image,
  };
}