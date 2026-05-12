// To parse this JSON data, do
//
//     final agentModel = agentModelFromJson(jsonString);

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

AgentModel agentModelFromJson(String? str) => AgentModel.fromJson(json.decode(str!));

String agentModelToJson(AgentModel data) => json.encode(data.toJson());

class AgentModel {
  final String? address;
  final String? cnic;
  final int? createdAt;
  final String? docId;
  final String? image;
  final bool? isActive;
  final bool? isCheckedIn;
  final String? name;
  final String? phoneNumber;
  final bool? isAdminVerified;
  final String? cityID;
  final City? city;

  AgentModel({
    this.address,
    this.cnic,
    this.createdAt,
    this.city,
    this.docId,
    this.image,
    this.isActive,
    this.isCheckedIn,
    this.name,
    this.phoneNumber,
    this.isAdminVerified,
    this.cityID,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) => AgentModel(
    address: json["address"],
    cnic: json["cnic"],
    createdAt: json["createdAt"],
    docId: json["docID"],
    image: json["image"],
    isActive: json["isActive"],
    isCheckedIn: json["isCheckedIn"],
    name: json["name"],
    phoneNumber: json["phone"],
    isAdminVerified: json["isAdminVerified"],
    cityID: json["cityID"],
    city: json["city"] == null ? null : City.fromJson(json["city"]),
  );

  Map<String, dynamic> toJson() => {
    "address": address,
    "cnic": cnic,
    "createdAt": createdAt,
    "docID": docId,
    "image": image,
    "isActive": isActive,
    "isCheckedIn": isCheckedIn,
    "name": name,
    "phone": phoneNumber,
    "isAdminVerified": isAdminVerified,
    "city": city?.toJson(),
    "cityID": cityID,
  };
}
class City {
  String? value;
  String? label;

  City({
    this.value,
    this.label,
  });

  factory City.fromJson(Map<String, dynamic> json) => City(
    value: json["value"],
    label: json["label"],
  );

  Map<String, dynamic> toJson() => {
    "value": value,
    "label": label,
  };
}