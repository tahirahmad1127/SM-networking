// To parse this JSON data, do
//
//     final termsConditionModel = termsConditionModelFromJson(jsonString);

import 'dart:convert';

TermsConditionModel termsConditionModelFromJson(String str) => TermsConditionModel.fromJson(json.decode(str));

String termsConditionModelToJson(TermsConditionModel data) => json.encode(data.toJson());

class TermsConditionModel {
  final String? msg;
  final String? data;

  TermsConditionModel({
    this.msg,
    this.data,
  });

  factory TermsConditionModel.fromJson(Map<String, dynamic> json) => TermsConditionModel(
    msg: json["msg"],
    data: json["data"],
  );

  Map<String, dynamic> toJson() => {
    "msg": msg,
    "data": data,
  };
}
