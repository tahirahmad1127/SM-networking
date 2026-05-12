// To parse this JSON data, do
//
//     final statsListingModel = statsListingModelFromJson(jsonString);

import 'dart:convert';

StatsListingModel statsListingModelFromJson(String str) =>
    StatsListingModel.fromJson(json.decode(str));

String statsListingModelToJson(StatsListingModel data) =>
    json.encode(data.toJson());

class StatsListingModel {
  final String? msg;
  final StatModel? data;

  StatsListingModel({
    this.msg,
    this.data,
  });

  factory StatsListingModel.fromJson(Map<String, dynamic> json) =>
      StatsListingModel(
        msg: json["msg"],
        data: json["data"] == null ? null : StatModel.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "msg": msg,
    "data": data?.toJson(),
  };
}

class StatModel {
  final int? orders;
  final int? shops;
  final int? sales;
  final int? todaySales;
  final List<MonthsSale>? monthsSales;
  final num? totalTarget;
  final num? achievedTarget;
  final num? remainingTarget;

  StatModel({
    this.orders,
    this.shops,
    this.sales,
    this.todaySales,
    this.monthsSales,
    this.totalTarget,
    this.achievedTarget,
    this.remainingTarget,
  });

  factory StatModel.fromJson(Map<String, dynamic> json) => StatModel(
    orders: json["orders"],
    shops: json["shops"],
    sales: json["sales"],
    todaySales: json["todaySales"],
    monthsSales: json["monthsSales"] == null
        ? []
        : List<MonthsSale>.from(
        json["monthsSales"]!.map((x) => MonthsSale.fromJson(x))),
    totalTarget: json["totalTarget"],
    achievedTarget: json["achievedTarget"],
    remainingTarget: json["remainingTarget"],
  );

  Map<String, dynamic> toJson() => {
    "orders": orders,
    "shops": shops,
    "sales": sales,
    "todaySales": todaySales,
    "monthsSales": monthsSales == null
        ? []
        : List<dynamic>.from(monthsSales!.map((x) => x.toJson())),
    "totalTarget": totalTarget,
    "achievedTarget": achievedTarget,
    "remainingTarget": remainingTarget,
  };
}

class MonthsSale {
  final String? month;
  final int? sales;

  MonthsSale({
    this.month,
    this.sales,
  });

  factory MonthsSale.fromJson(Map<String, dynamic> json) => MonthsSale(
    month: json["month"],
    sales: json["sales"],
  );

  Map<String, dynamic> toJson() => {
    "month": month,
    "sales": sales,
  };
}