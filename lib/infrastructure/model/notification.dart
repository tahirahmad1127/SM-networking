// To parse this JSON data, do
//
//     final notificationModel = notificationModelFromJson(jsonString);

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

NotificationModel notificationModelFromJson(String str) => NotificationModel.fromJson(json.decode(str));

String notificationModelToJson(NotificationModel data) => json.encode(data.toJson());

class NotificationModel {
  Timestamp? createdAt;
  String? docId;
  bool? isRead;
  String? subTitle;
  String? title;
  String? userId;

  NotificationModel({
    this.createdAt,
    this.docId,
    this.isRead,
    this.subTitle,
    this.title,
    this.userId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    createdAt: json["createdAt"],
    docId: json["docID"],
    isRead: json["isRead"],
    subTitle: json["subTitle"],
    title: json["title"],
    userId: json["userID"],
  );

  Map<String, dynamic> toJson() => {
    "createdAt": createdAt,
    "docID": docId,
    "isRead": isRead,
    "subTitle": subTitle,
    "title": title,
    "userID": userId,
  };
}
