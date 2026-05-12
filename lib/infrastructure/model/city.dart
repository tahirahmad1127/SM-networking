// To parse this JSON data, do
//
//     final cityModel = cityModelFromJson(jsonString);

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

CityModel cityModelFromJson(String str) => CityModel.fromJson(json.decode(str));

String cityModelToJson(CityModel data) => json.encode(data.toJson());

class CityModel {
  Timestamp? createdAt;
  String? docId;
  String? name;

  CityModel({
    this.createdAt,
    this.docId,
    this.name,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
    createdAt: json["createdAt"],
    docId: json["docID"],
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {
    "createdAt": createdAt,
    "docID": docId,
    "name": name,
  };
}
