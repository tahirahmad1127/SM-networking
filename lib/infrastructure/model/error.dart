// To parse this JSON data, do
//
//     final globalErrorModel = globalErrorModelFromJson(jsonString);

import 'dart:convert';

GlobalErrorModel globalErrorModelFromJson(String str) => GlobalErrorModel.fromJson(json.decode(str));

String globalErrorModelToJson(GlobalErrorModel data) => json.encode(data.toJson());

class GlobalErrorModel {
  final String? error;
  final String? code;
  final bool canForceLogin;

  GlobalErrorModel({
    this.error,
    this.code,
    this.canForceLogin = false,
  });

  factory GlobalErrorModel.fromJson(Map<String, dynamic> json) => GlobalErrorModel(
    error: json["error"] ?? json["errors"],
    code: json["code"],
    canForceLogin: json["canForceLogin"] == true,
  );

  Map<String, dynamic> toJson() => {
    "errors": error,
    "code": code,
    "canForceLogin": canForceLogin,
  };
}