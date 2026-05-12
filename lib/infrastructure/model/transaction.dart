// To parse this JSON data, do
//
//     final transactionModel = transactionModelFromJson(jsonString);

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

TransactionModel transactionModelFromJson(String str) =>
    TransactionModel.fromJson(json.decode(str));

String transactionModelToJson(TransactionModel data) =>
    json.encode(data.toJson(data.docId.toString()));

class TransactionModel {
  TransactionModel({
    this.docId,
    this.salesPersonID,
    this.orderID,
    this.amount,
    this.date,
  });

  String? docId;
  String? salesPersonID;
  String? orderID;
  num? amount;
  Timestamp? date;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        docId: json["docID"],
        salesPersonID: json["salesPersonID"],
        amount: json["amount"],
        orderID: json["orderID"],
        date: json["date"],
      );

  Map<String, dynamic> toJson(String docID) => {
        "docID": docID,
        "salesPersonID": salesPersonID,
        "amount": amount,
        "orderID": orderID,
        "date": Timestamp.fromDate(DateTime.now()),
      };
}
