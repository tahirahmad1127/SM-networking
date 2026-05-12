// To parse this JSON data, do
//
//     final visitModel = visitModelFromJson(jsonString);

import 'dart:convert';

VisitModel visitModelFromJson(String str) => VisitModel.fromJson(json.decode(str));

String visitModelToJson(VisitModel data) => json.encode(data.toJson());

class VisitModel {
  final String? id;
  final String? retailerId;
  final String? salesPersonId;
  final String? startTime;
  final String? endTime;
  final String? date;
  final String? createdAt;
  final String? updatedAt;
  final String? image;

  VisitModel({
    this.id,
    this.retailerId,
    this.salesPersonId,
    this.startTime,
    this.endTime,
    this.date,
    this.createdAt,
    this.updatedAt,
    this.image,
  });

  factory VisitModel.fromJson(Map<String, dynamic> json) => VisitModel(
    id: json["_id"],
    retailerId: json["retailerID"],
    salesPersonId: json["salesPersonID"],
    startTime: json["startTime"],
    endTime: json["endTime"],
    date: json["date"],
    createdAt: json["createdAt"],
    updatedAt: json["updatedAt"],
    image: json["image"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "retailerID": retailerId,
    "salesPersonID": salesPersonId,
    "startTime": startTime,
    "endTime": endTime,
    "date": date,
    "createdAt": createdAt,
    "updatedAt": updatedAt,
    "image": image,
  };

  @override
  String toString() {
    return 'VisitModel(id: $id, retailerId: $retailerId, salesPersonId: $salesPersonId, startTime: $startTime, endTime: $endTime, date: $date, image: $image, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
