// To parse this JSON data, do
//
//     final bannerModel = bannerModelFromJson(jsonString);

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

BannerModel bannerModelFromJson(String str) =>
    BannerModel.fromJson(json.decode(str));

String bannerModelToJson(BannerModel data) => json.encode(data.toJson());

class BannerModel {
  String? cityId;
  Timestamp? createdAt;
  String? description;
  String? docId;
  String? brandID;
  String? brandEnglishName;
  String? brandUrduName;
  String? image;
  bool? isActive;

  BannerModel({
    this.cityId,
    this.createdAt,
    this.description,
    this.docId,
    this.image,
    this.isActive,
    this.brandEnglishName,
    this.brandUrduName,
    this.brandID,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
        cityId: json["cityID"],
        createdAt: json["createdAt"],
        description: json["description"],
        docId: json["docID"],
        image: json["image"],
    brandEnglishName: json["brandEnglishName"],
    brandUrduName: json["brandUrduName"],
        isActive: json["isActive"],
    brandID: json["brandID"],
      );

  Map<String, dynamic> toJson() => {
        "cityID": cityId,
        "createdAt": createdAt,
        "description": description,
        "docID": docId,
        "image": image,
        "brandEnglishName": brandEnglishName,
        "brandUrduName": brandUrduName,
        "isActive": isActive,
        "brandID": brandID,
      };
}
