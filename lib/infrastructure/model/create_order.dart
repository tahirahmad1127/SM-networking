// To parse this JSON data, do
//
//     final createOrderModel = createOrderModelFromJson(jsonString);

import 'dart:convert';

CreateOrderModel createOrderModelFromJson(String str) => CreateOrderModel.fromJson(json.decode(str));

String createOrderModelToJson(CreateOrderModel data) => json.encode(data.toJson());

class CreateOrderModel {
  final String? retailerUser;
  final String? saleUser;
  final String? city;
  final String? phoneNumber;
  final String? paymentType;
  final String? couponCode;
  final String? shippingAddress;
  final List<OrderItem>? items;
  final double? bulkDiscount;
  final double? couponDiscount;

  CreateOrderModel({
    this.retailerUser,
    this.saleUser,
    this.phoneNumber,
    this.paymentType,
    this.shippingAddress,
    this.city,
    this.couponCode,
    this.items,
    this.bulkDiscount,      // New parameter
    this.couponDiscount,    // New parameter
  });

  factory CreateOrderModel.fromJson(Map<String, dynamic> json) => CreateOrderModel(
    retailerUser: json["RetailerUser"],
    saleUser: json["SaleUser"],
    phoneNumber: json["phoneNumber"],
    paymentType: json["paymentType"],
    city: json["city"],
    couponCode: json["couponCode"],
    shippingAddress: json["shippingAddress"],
    items: json["items"] == null ? [] : List<OrderItem>.from(json["items"]!.map((x) => OrderItem.fromJson(x))),
    bulkDiscount: json["bulkDiscount"]?.toDouble(),
    couponDiscount: json["couponDiscount"]?.toDouble(),
  );

  Map<String, dynamic> toJson() {
    final map = {
      "RetailerUser": retailerUser,
      "SaleUser": saleUser,
      "phoneNumber": phoneNumber,
      "city": city,
      "couponCode": couponCode,
      "paymentType": paymentType,
      "shippingAddress": shippingAddress,
      "items": items == null ? [] : List<dynamic>.from(items!.map((x) => x.toJson())),
    };

    // Only add discount fields if they have values > 0
    if (bulkDiscount != null && bulkDiscount! > 0) {
      map["bulkDiscount"] = bulkDiscount;
    }

    if (couponDiscount != null && couponDiscount! > 0) {
      map["couponDiscount"] = couponDiscount;
    }

    return map;
  }
}

class OrderItem {
  final String? productId;
  final int? quantity;
  final int? price;
  final int? discountedPrice;
  final int? cartonSize;
  final String? type;

  OrderItem({
    this.productId,
    this.quantity,
    this.cartonSize,
    this.price,
    this.discountedPrice,
    this.type,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json["productId"],
    quantity: json["quantity"],
    cartonSize: json["cartonSize"],
    price: json["price"],
    discountedPrice: json["discountedPrice"],
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "productId": productId,
    "quantity": quantity,
    "price": price,
    "discountedPrice": discountedPrice,
    "cartonSize": cartonSize,
    "type": type,
  };
}