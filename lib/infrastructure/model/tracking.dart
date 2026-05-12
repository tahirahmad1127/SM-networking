// To parse this JSON data, do
//
//     final trackingResponseModel = trackingResponseModelFromJson(jsonString);

import 'dart:convert';

TrackingResponseModel trackingResponseModelFromJson(String str) =>
    TrackingResponseModel.fromJson(json.decode(str));

String trackingResponseModelToJson(TrackingResponseModel data) =>
    json.encode(data.toJson());

class TrackingResponseModel {
  final String? msg;
  final TrackingData? data;

  TrackingResponseModel({
    this.msg,
    this.data,
  });

  factory TrackingResponseModel.fromJson(Map<String, dynamic> json) =>
      TrackingResponseModel(
        msg: json["msg"],
        data: json["data"] == null ? null : TrackingData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "msg": msg,
    "data": data?.toJson(),
  };
}

class TrackingData {
  final String? id;
  final String? salesPersonId;
  final String? date;
  final List<Session>? sessions;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  TrackingData({
    this.id,
    this.salesPersonId,
    this.date,
    this.sessions,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory TrackingData.fromJson(Map<String, dynamic> json) => TrackingData(
    id: json["_id"],
    salesPersonId: json["salesPersonID"],
    date: json["date"],
    sessions: json["sessions"] == null
        ? []
        : List<Session>.from(
        json["sessions"].map((x) => Session.fromJson(x))),
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
    "salesPersonID": salesPersonId,
    "date": date,
    "sessions": sessions == null
        ? []
        : List<dynamic>.from(sessions!.map((x) => x.toJson())),
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
  };
}

class Session {
  final String? checkInTime;
  final String? checkOutTime;
  final List<Coordinate>? coordinates;

  Session({
    this.checkInTime,
    this.checkOutTime,
    this.coordinates,
  });

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    checkInTime: json["checkInTime"],
    checkOutTime: json["checkOutTime"],
    coordinates: json["coordinates"] == null
        ? []
        : List<Coordinate>.from(
        json["coordinates"].map((x) => Coordinate.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "checkInTime": checkInTime,
    "checkOutTime": checkOutTime,
    "coordinates": coordinates == null
        ? []
        : List<dynamic>.from(coordinates!.map((x) => x.toJson())),
  };
}

class Coordinate {
  final double? lat;
  final double? lng;
  final String? timestamp;

  Coordinate({
    this.lat,
    this.lng,
    this.timestamp,
  });

  factory Coordinate.fromJson(Map<String, dynamic> json) => Coordinate(
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
    timestamp: json["timestamp"],
  );

  Map<String, dynamic> toJson() => {
    "lat": lat,
    "lng": lng,
    "timestamp": timestamp,
  };
}

// Request body model
class TrackingRequestModel {
  final String salesPersonID;
  final double lat;
  final double lng;
  final String date;

  TrackingRequestModel({
    required this.salesPersonID,
    required this.lat,
    required this.lng,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    "salesPersonID": salesPersonID,
    "lat": lat,
    "lng": lng,
    "date": date,
  };
}