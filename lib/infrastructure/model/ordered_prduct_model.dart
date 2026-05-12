// To parse this JSON data, do
//
//     final farmProductModel = farmProductModelFromJson(jsonString);

import 'dart:convert';

OrderedProductModel orderedProductModelFromJson(String str) =>
    OrderedProductModel.fromJson(json.decode(str));

String orderedProductModelToJson(OrderedProductModel data) =>
    json.encode(data.toJson(data.productId.toString()));

class OrderedProductModel {
  OrderedProductModel({
    this.productId,
    this.catId,
    this.images,
    this.price,
    this.productName,
    this.productDescription,
    this.address,
  });

  String? productId;
  String? catId;
  String? images;
  String? price;
  String? productName;
  String? productDescription;
  String? address;

  factory OrderedProductModel.fromJson(Map<String, dynamic> json) =>
      OrderedProductModel(
        productId: json["productID"],
        catId: json["catID"],
        images: json["images"],
        price: json["price"],
        productName: json["productName"],
        productDescription: json["productDescription"],
        address: json["address"],
      );

  Map<String, dynamic> toJson(String docID) => {
        "productID": docID,
        "catID": catId,
        "images": images,
        "price": price,
        "productName": productName,
        "productDescription": productDescription,
        "address": address,
      };
}
