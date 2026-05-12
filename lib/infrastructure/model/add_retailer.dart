// To parse this JSON data, do
//
//     final addRetailerModel = addRetailerModelFromJson(jsonString);

import 'dart:convert';

AddRetailerModel addRetailerModelFromJson(String str) => AddRetailerModel.fromJson(json.decode(str));

String addRetailerModelToJson(AddRetailerModel data) => json.encode(data.toJson());

class AddRetailerModel {
  final String? shopName;
  final String? shopCategory;
  final String? shopAddress2;
  final String? shopAddress1;
  final String? name;
  final String? phoneNumber;
  final String? lat;
  final String? lng;
  final String? distance;
  final String? file;
  final String? cnic;
  final String? salesPersonId;
  final String? cityId;

  AddRetailerModel({
    this.shopName,
    this.shopCategory,
    this.shopAddress2,
    this.shopAddress1,
    this.file,
    this.name,
    this.phoneNumber,
    this.lat,
    this.lng,
    this.distance,
    this.cnic,
    this.salesPersonId,
    this.cityId,
  });

  factory AddRetailerModel.fromJson(Map<String, dynamic> json) => AddRetailerModel(
    shopName: json["shopName"],
    shopCategory: json["shopCategory"],
    shopAddress2: json["shopAddress2"],
    shopAddress1: json["shopAddress1"],
    file: json["file"],
    name: json["name"],
    phoneNumber: json["phoneNumber"],
    lat: json["lat"],
    lng: json["lng"],
    distance: json["distance"],
    cnic: json["cnic"],
    salesPersonId: json["salesPersonID"],
    cityId: json["cityID"],
  );

  Map<String, dynamic> toJson() => {
    "shopName": shopName,
    "shopCategory": shopCategory,
    "shopAddress2": shopAddress2,
    "shopAddress1": shopAddress1,
    "file": file,
    "name": name,
    "phoneNumber": phoneNumber,
    "lat": lat,
    "lng": lng,
    "distance": distance,
    "cnic": cnic,
    "salesPersonID": salesPersonId,
    "cityID": cityId,
  };
}
