// To parse this JSON data, do
//
//     final privacyPolicyModel = privacyPolicyModelFromJson(jsonString);

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
PrivacyPolicyModel privacyPolicyModelFromJson(String str) => PrivacyPolicyModel.fromJson(json.decode(str));

String privacyPolicyModelToJson(PrivacyPolicyModel data) => json.encode(data.toJson());

class PrivacyPolicyModel {
  Timestamp? createdAt;
  String? docId;

  String? text;

  PrivacyPolicyModel({
    this.createdAt,
    this.docId,
    this.text,
  });


  factory PrivacyPolicyModel.fromJson(Map<String, dynamic> json) => PrivacyPolicyModel(
    createdAt: json["createdAt"],
    docId: json["docID"],
    text: json["text"],
  );

  Map<String, dynamic> toJson() => {
    "createdAt": createdAt,
    "docID": docId,
    "text": text,
  };
}
