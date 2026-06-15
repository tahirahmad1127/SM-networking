import 'dart:convert';

import 'package:sm_networking/infrastructure/model/product.dart';

List<CartModel> cartModelFromJson(String? str) =>
    List<CartModel>.from(json.decode(str!).map((x) => CartModel.fromJson(x)));

String cartModelToJson(List<CartModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CartModel {
  String name;
  String id;
  String price;
  String image;
  bool offer;
  int quantity;
  int totalQuantity;
  ProductModel productDetails;
  String type;
  String? discountedPrice;

  CartModel({
    required this.name,
    required this.id,
    required this.price,
    required this.image,
    required this.offer,
    required this.quantity,
    required this.totalQuantity,
    required this.productDetails,
    required this.type,
    this.discountedPrice,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) => CartModel(
    name: json["name"],
    id: json["id"],
    price: json["price"],
    image: json["image"],
    offer: json["offer"],
    quantity: json["quantity"],
    totalQuantity: json["totalQuantity"],
    productDetails: ProductModel.fromJson(
        json["productDetails"] as Map<String, dynamic>),
    type: json["type"] ?? "ctn",
    discountedPrice: json["discountedPrice"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "id": id,
    "price": price,
    "image": image,
    "offer": offer,
    "quantity": quantity,
    "totalQuantity": totalQuantity,
    "productDetails": productDetails.toJson(),
    "type": type,
    if (discountedPrice != null) "discountedPrice": discountedPrice,
  };
}