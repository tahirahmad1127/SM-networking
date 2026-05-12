import 'dart:convert';

CouponModel couponModelFromJson(String str) =>
    CouponModel.fromJson(json.decode(str));

String couponModelToJson(CouponModel data) => json.encode(data.toJson());

class CouponModel {
  final String? couponCode;
  final String? discountType;
  final double? discountValue;
  final double? totalDiscount;
  final double? finalPrice;
  final List<CouponProduct>? products;

  CouponModel({
    this.couponCode,
    this.discountType,
    this.discountValue,
    this.totalDiscount,
    this.finalPrice,
    this.products,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) => CouponModel(
    couponCode: json["couponCode"],
    discountType: json["discountType"],
    discountValue: json["discountValue"]?.toDouble(),
    totalDiscount: json["totalDiscount"]?.toDouble(),
    finalPrice: json["finalPrice"]?.toDouble(),
    products: json["products"] == null
        ? []
        : List<CouponProduct>.from(
        json["products"].map((x) => CouponProduct.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "couponCode": couponCode,
    "discountType": discountType,
    "discountValue": discountValue,
    "totalDiscount": totalDiscount,
    "finalPrice": finalPrice,
    "products": products == null
        ? []
        : List<dynamic>.from(products!.map((x) => x.toJson())),
  };
}

class CouponProduct {
  final String? productId;
  final String? productName;
  final double? originalPrice;
  final double? discountAmount;
  final double? discountedPrice;

  CouponProduct({
    this.productId,
    this.productName,
    this.originalPrice,
    this.discountAmount,
    this.discountedPrice,
  });

  factory CouponProduct.fromJson(Map<String, dynamic> json) => CouponProduct(
    productId: json["productId"],
    productName: json["productName"],
    originalPrice: json["originalPrice"]?.toDouble(),
    discountAmount: json["discountAmount"]?.toDouble(),
    discountedPrice: json["discountedPrice"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "productId": productId,
    "productName": productName,
    "originalPrice": originalPrice,
    "discountAmount": discountAmount,
    "discountedPrice": discountedPrice,
  };
}
