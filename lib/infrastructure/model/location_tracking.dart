// To parse this JSON data, do
//
//     final locationTrackingModel = locationTrackingModelFromJson(jsonString);

import 'dart:convert';

LocationTrackingModel locationTrackingModelFromJson(String str) =>
    LocationTrackingModel.fromJson(json.decode(str));

String locationTrackingModelToJson(LocationTrackingModel data) =>
    json.encode(data.toJson());

class LocationTrackingModel {
  final String? id;
  final String? userId;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LocationTrackingModel({
    this.id,
    this.userId,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  factory LocationTrackingModel.fromJson(Map<String, dynamic> json) =>
      LocationTrackingModel(
        id: json["_id"] ?? json["id"], // Support Firestore doc or API id
        userId: json["userId"],
        latitude: (json["latitude"] is int)
            ? (json["latitude"] as int).toDouble()
            : json["latitude"]?.toDouble(),
        longitude: (json["longitude"] is int)
            ? (json["longitude"] as int).toDouble()
            : json["longitude"]?.toDouble(),
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.tryParse(json["createdAt"].toString()),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.tryParse(json["updatedAt"].toString()),
      );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "userId": userId,
    "latitude": latitude,
    "longitude": longitude,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };

  /// Firestore-style conversion
  factory LocationTrackingModel.fromMap(Map<String, dynamic> map, String id) {
    return LocationTrackingModel(
      id: id,
      userId: map['userId'],
      latitude: (map['latitude'] is int)
          ? (map['latitude'] as int).toDouble()
          : map['latitude']?.toDouble(),
      longitude: (map['longitude'] is int)
          ? (map['longitude'] as int).toDouble()
          : map['longitude']?.toDouble(),
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.tryParse(map['createdAt']?.toString() ?? ''),
      updatedAt: map['updatedAt'] is DateTime
          ? map['updatedAt']
          : DateTime.tryParse(map['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'latitude': latitude,
    'longitude': longitude,
    'createdAt': createdAt?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };
}
