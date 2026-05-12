// To parse this JSON data, do
//
//     final productListingModel = productListingModelFromJson(jsonString);

import 'dart:convert';

ProductListingModel productListingModelFromJson(String str) =>
    ProductListingModel.fromJson(json.decode(str));

String productListingModelToJson(ProductListingModel data) =>
    json.encode(data.toJson());

class ProductListingModel {
  final String? msg;
  final List<ProductModel>? data;

  ProductListingModel({
    this.msg,
    this.data,
  });

  /// The API returns products under either "data" or "products" key depending
  /// on the endpoint. We handle both here so no endpoint ever returns null.
  factory ProductListingModel.fromJson(Map<String, dynamic> json) {
    final rawList = json["products"] ?? json["data"];
    return ProductListingModel(
      msg: json["msg"],
      data: rawList == null
          ? []
          : List<ProductModel>.from(
          (rawList as List).map((x) => ProductModel.fromJson(x))),
    );
  }

  Map<String, dynamic> toJson() => {
    "msg": msg,
    "data": data == null
        ? []
        : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}

class ProductModel {
  final String? id;
  final String? urduTitle;
  final String? englishTitle;
  final String? image;
  final String? urduDescription;
  final String? englishDescription;
  final num? price;
  final int? stock;
  final int? cortanSize;
  final int? piecesPerBox;
  final String? packaging;
  final num? purchaseRate;
  final num? purchaseRatePercent;
  final num? saleRate;
  final num? scheme;
  final String? schemeType;
  final CityId? cityId;

  /// The API returns "brand" as either a plain String ID  OR  a nested object
  /// { "_id": "...", "englishName": "..." }.  We normalise both into ProductRef.
  final ProductRef? brand;

  /// "category" is always a nested object { "_id": "...", "englishName": "..." }.
  final ProductRef? category;

  final bool? includePacking;
  final String? packings;
  final bool? includeBulkOrder;
  final List<dynamic>? bulkOrders;
  final bool? isDiscounted;
  final bool? isDeleted;
  final String? discountType;
  final int? discount;
  final bool? isActive;
  final bool? isFocused;
  final bool? adminVerified;
  final String? productId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  // Bulk discount fields
  final List<num>? bulkDiscountQuantity;
  final List<num>? bulkDiscount;
  final List<String>? bulkDiscountType;

  ProductModel({
    this.id,
    this.urduTitle,
    this.englishTitle,
    this.image,
    this.urduDescription,
    this.englishDescription,
    this.price,
    this.stock,
    this.cortanSize,
    this.piecesPerBox,
    this.packaging,
    this.purchaseRate,
    this.purchaseRatePercent,
    this.saleRate,
    this.scheme,
    this.schemeType,
    this.cityId,
    this.brand,
    this.category,
    this.includePacking,
    this.packings,
    this.includeBulkOrder,
    this.bulkOrders,
    this.isDiscounted,
    this.isDeleted,
    this.discountType,
    this.discount,
    this.isActive,
    this.isFocused,
    this.adminVerified,
    this.productId,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.bulkDiscountQuantity,
    this.bulkDiscount,
    this.bulkDiscountType,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
    id: json["_id"],
    urduTitle: json["urduTitle"],
    englishTitle: json["englishTitle"],
    image: json["image"],
    urduDescription: json["urduDescription"],
    englishDescription: json["englishDescription"],
    price: json["price"],
    stock: json["stock"],
    cortanSize: json["cortanSize"],
    piecesPerBox: json["piecesPerBox"],
    packaging: json["packaging"],
    purchaseRate: json["purchaseRate"],
    purchaseRatePercent: json["purchaseRatePercent"],
    saleRate: json["saleRate"],
    scheme: json["scheme"],
    schemeType: json["schemeType"],
    cityId: json["cityID"] == null ? null : CityId.fromJson(json["cityID"]),

    // "brand" can be a plain String ID or a Map — handle both safely.
    brand: _parseProductRef(json["brand"]),

    // "category" is always a Map.
    category: json["category"] == null
        ? null
        : ProductRef.fromJson(json["category"] as Map<String, dynamic>),

    includePacking: json["includePacking"],
    packings: json["packings"],
    includeBulkOrder: json["includeBulkOrder"],
    bulkOrders: json["bulkOrders"] == null
        ? []
        : List<dynamic>.from(json["bulkOrders"]!.map((x) => x)),
    isDiscounted: json["isDiscounted"],
    isDeleted: json["isDeleted"],
    discountType: json["discountType"],
    discount: json["discount"],
    isActive: json["isActive"],
    isFocused: json["isFocused"],
    adminVerified: json["adminVerified"],
    productId: json["productId"],
    createdAt: json["createdAt"] == null
        ? null
        : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null
        ? null
        : DateTime.parse(json["updatedAt"]),
    v: json["__v"],
    bulkDiscountQuantity: json["bulkDiscountQuantity"] == null
        ? []
        : List<num>.from(json["bulkDiscountQuantity"]!.map((x) => x)),
    bulkDiscount: json["bulkDiscount"] == null
        ? []
        : List<num>.from(json["bulkDiscount"]!.map((x) => x)),
    bulkDiscountType: json["bulkDiscountType"] == null
        ? []
        : List<String>.from(
        json["bulkDiscountType"]!.map((x) => x.toString())),
  );

  /// Safely converts the "brand" field regardless of whether the API sends a
  /// plain String (just the _id) or a full object { "_id": ..., "englishName": ... }.
  static ProductRef? _parseProductRef(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      // Plain ID string — wrap it so the rest of the app can read .id normally.
      return ProductRef(id: value, englishName: null);
    }
    if (value is Map<String, dynamic>) {
      return ProductRef.fromJson(value);
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "urduTitle": urduTitle,
    "englishTitle": englishTitle,
    "image": image,
    "urduDescription": urduDescription,
    "englishDescription": englishDescription,
    "price": price,
    "stock": stock,
    "cortanSize": cortanSize,
    "piecesPerBox": piecesPerBox,
    "packaging": packaging,
    "purchaseRate": purchaseRate,
    "purchaseRatePercent": purchaseRatePercent,
    "saleRate": saleRate,
    "scheme": scheme,
    "schemeType": schemeType,
    "cityID": cityId?.toJson(),
    "brand": brand?.toJson(),
    "category": category?.toJson(),
    "includePacking": includePacking,
    "packings": packings,
    "includeBulkOrder": includeBulkOrder,
    "bulkOrders": bulkOrders == null
        ? []
        : List<dynamic>.from(bulkOrders!.map((x) => x)),
    "isDiscounted": isDiscounted,
    "isDeleted": isDeleted,
    "discountType": discountType,
    "discount": discount,
    "isActive": isActive,
    "isFocused": isFocused,
    "adminVerified": adminVerified,
    "productId": productId,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
    "bulkDiscountQuantity": bulkDiscountQuantity == null
        ? []
        : List<dynamic>.from(bulkDiscountQuantity!.map((x) => x)),
    "bulkDiscount": bulkDiscount == null
        ? []
        : List<dynamic>.from(bulkDiscount!.map((x) => x)),
    "bulkDiscountType": bulkDiscountType == null
        ? []
        : List<dynamic>.from(bulkDiscountType!.map((x) => x)),
  };
}

/// Represents a brand or category reference embedded in a product.
class ProductRef {
  final String? id;
  final String? englishName;

  ProductRef({
    this.id,
    this.englishName,
  });

  factory ProductRef.fromJson(Map<String, dynamic> json) => ProductRef(
    id: json["_id"],
    englishName: json["englishName"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "englishName": englishName,
  };
}

class CityId {
  final String? id;
  final String? name;

  CityId({
    this.id,
    this.name,
  });

  factory CityId.fromJson(Map<String, dynamic> json) => CityId(
    id: json["_id"],
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
  };
}