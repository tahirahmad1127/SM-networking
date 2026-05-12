// To parse this JSON data, do
//
//     final bulkModel = bulkModelFromJson(jsonString);

import 'dart:convert';

BulkModel bulkModelFromJson(String str) => BulkModel.fromJson(json.decode(str));

String bulkModelToJson(BulkModel data) => json.encode(data.toJson());

class BulkModel {
  String? dcoId;
  num? discount;
  num? quantity;

  BulkModel({
    this.dcoId,
    this.discount,
    this.quantity,
  });

  factory BulkModel.fromJson(Map<String, dynamic> json) => BulkModel(
    dcoId: json["dcoID"],
    discount: json["discount"],
    quantity: json["quantity"],
  );

  Map<String, dynamic> toJson() => {
    "dcoID": dcoId,
    "discount": discount,
    "quantity": quantity,
  };
}
