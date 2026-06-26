// To parse this JSON data, do
//
//     final attendanceModel = attendanceModelFromJson(jsonString);

import 'dart:convert';

AttendanceModel attendanceModelFromJson(String str) => AttendanceModel.fromJson(json.decode(str));

String attendanceModelToJson(AttendanceModel data) => json.encode(data.toJson());

class AttendanceModel {
  final String? salesPersonId;
  final String? date;
  final double? lat;
  final double? lng;
  final String? checkInTime;
  final String? checkOutTime;
  final bool? isDeleted;
  final String? id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;
  final String? userType;
  final String? distributorId;

  AttendanceModel({
    this.salesPersonId,
    this.date,
    this.lat,
    this.lng,
    this.checkInTime,
    this.checkOutTime,
    this.isDeleted,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.userType,
    this.distributorId,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) => AttendanceModel(
    salesPersonId: json["salesPersonID"],
    date: json["date"],
    lat: (json["lat"] != null) ? json["lat"].toDouble() : null,
    lng: (json["lng"] != null) ? json["lng"].toDouble() : null,
    checkInTime: json["checkInTime"],
    checkOutTime: json["checkOutTime"],
    isDeleted: json["isDeleted"],
    id: json["_id"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    v: json["__v"],
  );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      "salesPersonID": salesPersonId,
      "date": date,
      "lat": lat,
      "lng": lng,
      "checkInTime": checkInTime,
      "checkOutTime": checkOutTime,
      "isDeleted": isDeleted,
      "_id": id,
      "createdAt": createdAt?.toIso8601String(),
      "updatedAt": updatedAt?.toIso8601String(),
      "__v": v,
    };
    if (userType != null) map["userType"] = userType;
    if (distributorId != null) map["distributorId"] = distributorId;
    return map;
  }

  @override
  String toString() {
    return 'AttendanceModel(salesPersonId: $salesPersonId, date: $date, lat: $lat, lng: $lng, checkInTime: $checkInTime, checkOutTime: $checkOutTime, isDeleted: $isDeleted, id: $id, createdAt: $createdAt, updatedAt: $updatedAt, v: $v)';
  }
}