// To parse this JSON data, do
//
//     final orderListingModel = orderListingModelFromJson(jsonString);

import 'dart:convert';

OrderListingModel orderListingModelFromJson(String str) => OrderListingModel.fromJson(json.decode(str));

String orderListingModelToJson(OrderListingModel data) => json.encode(data.toJson());

class OrderListingModel {
  final String? msg;
  final List<OrderModel>? data;
  final int? totalPages;

  OrderListingModel({
    this.msg,
    this.data,
    this.totalPages,
  });

  factory OrderListingModel.fromJson(Map<String, dynamic> json) => OrderListingModel(
    msg: json["msg"],
    data: json["data"] == null ? [] : List<OrderModel>.from(json["data"]!.map((x) => OrderModel.fromJson(x))),
    totalPages: json["totalPages"],
  );

  Map<String, dynamic> toJson() => {
    "msg": msg,
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    "totalPages": totalPages,
  };
}

class OrderModel {
  final String? id;
  final RetailerUser? warehouseManager;
  final SaleUser? salesPerson;
  final String? shippingAddress;
  final String? phoneNumber;
  final String? expectedDelivery;
  final List<Item>? items;
  final int? total;
  final List<Status>? statuses;
  final String? paymentType;
  final String? status;
  final bool? isPaymentClear;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;
  final num? bulkDiscount;      // ← Added
  final num? couponDiscount;    // ← Added
  final String? coupon;         // ← Added (coupon code)

  OrderModel({
    this.id,
    this.warehouseManager,
    this.salesPerson,
    this.shippingAddress,
    this.phoneNumber,
    this.expectedDelivery,
    this.items,
    this.total,
    this.statuses,
    this.paymentType,
    this.status,
    this.isPaymentClear,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.bulkDiscount,      // ← Added
    this.couponDiscount,    // ← Added
    this.coupon,            // ← Added
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: json["_id"],
    warehouseManager: json["warehouseManager"] == null ? null : RetailerUser.fromJson(json["warehouseManager"]),
    salesPerson: json["salesPerson"] == null ? null : SaleUser.fromJson(json["salesPerson"]),
    shippingAddress: json["shippingAddress"],
    phoneNumber: json["phoneNumber"],
    expectedDelivery: json["expectedDelivery"],
    items: json["items"] == null ? [] : List<Item>.from(json["items"]!.map((x) => Item.fromJson(x))),
    total: json["total"],
    statuses: json["statuses"] == null ? [] : List<Status>.from(json["statuses"]!.map((x) => Status.fromJson(x))),
    paymentType: json["paymentType"],
    status: json["status"],
    isPaymentClear: json["isPaymentClear"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    v: json["__v"],
    bulkDiscount: json["bulkDiscount"],      // ← Added
    couponDiscount: json["couponDiscount"],  // ← Added
    coupon: json["coupon"],                  // ← Added
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "warehouseManager": warehouseManager?.toJson(),
    "salesPerson": salesPerson?.toJson(),
    "shippingAddress": shippingAddress,
    "phoneNumber": phoneNumber,
    "expectedDelivery": expectedDelivery,
    "items": items == null ? [] : List<dynamic>.from(items!.map((x) => x.toJson())),
    "total": total,
    "statuses": statuses == null ? [] : List<dynamic>.from(statuses!.map((x) => x.toJson())),
    "paymentType": paymentType,
    "status": status,
    "isPaymentClear": isPaymentClear,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
    "bulkDiscount": bulkDiscount,      // ← Added
    "couponDiscount": couponDiscount,  // ← Added
    "coupon": coupon,                  // ← Added
  };
}

class Item {
  final ProductId? productId;
  final int? quantity;
  final int? price;
  final int? discountedPrice;
  final String? id;
  final String? type;

  Item({
    this.productId,
    this.quantity,
    this.price,
    this.discountedPrice,
    this.id,
    this.type,
  });

  factory Item.fromJson(Map<String, dynamic> json) => Item(
    productId: json["productId"] == null ? null : ProductId.fromJson(json["productId"]),
    quantity: json["quantity"],
    price: json["price"],
    discountedPrice: json["discountedPrice"],
    id: json["_id"],
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "productId": productId?.toJson(),
    "quantity": quantity,
    "price": price,
    "discountedPrice": discountedPrice,
    "_id": id,
    "type": type,
  };
}

class ProductId {
  final String? id;
  final String? urduTitle;
  final String? englishTitle;
  final String? image;
  final String? urduDescription;
  final String? englishDescription;
  final int? price;
  final int? stock;
  final String? cityId;
  final String? brandId;
  final String? categoryId;
  final bool? includePacking;
  final bool? includeBulkOrder;
  final List<dynamic>? bulkOrders;
  final bool? isDiscounted;
  final bool? isDeleted;
  final String? discountType;
  final int? discount;
  final bool? isActive;
  final bool? adminVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  ProductId({
    this.id,
    this.urduTitle,
    this.englishTitle,
    this.image,
    this.urduDescription,
    this.englishDescription,
    this.price,
    this.stock,
    this.cityId,
    this.brandId,
    this.categoryId,
    this.includePacking,
    this.includeBulkOrder,
    this.bulkOrders,
    this.isDiscounted,
    this.isDeleted,
    this.discountType,
    this.discount,
    this.isActive,
    this.adminVerified,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory ProductId.fromJson(Map<String, dynamic> json) => ProductId(
    id: json["_id"],
    urduTitle: json["urduTitle"],
    englishTitle: json["englishTitle"],
    image: json["image"],
    urduDescription: json["urduDescription"],
    englishDescription: json["englishDescription"],
    price: json["price"],
    stock: json["stock"],
    cityId: json["cityID"],
    brandId: json["brandID"],
    categoryId: json["categoryID"],
    includePacking: json["includePacking"],
    includeBulkOrder: json["includeBulkOrder"],
    bulkOrders: json["bulkOrders"] == null ? [] : List<dynamic>.from(json["bulkOrders"]!.map((x) => x)),
    isDiscounted: json["isDiscounted"],
    isDeleted: json["isDeleted"],
    discountType: json["discountType"],
    discount: json["discount"],
    isActive: json["isActive"],
    adminVerified: json["adminVerified"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    v: json["__v"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "urduTitle": urduTitle,
    "englishTitle": englishTitle,
    "image": image,
    "urduDescription": urduDescription,
    "englishDescription": englishDescription,
    "price": price,
    "stock": stock,
    "cityID": cityId,
    "brandID": brandId,
    "categoryID": categoryId,
    "includePacking": includePacking,
    "includeBulkOrder": includeBulkOrder,
    "bulkOrders": bulkOrders == null ? [] : List<dynamic>.from(bulkOrders!.map((x) => x)),
    "isDiscounted": isDiscounted,
    "isDeleted": isDeleted,
    "discountType": discountType,
    "discount": discount,
    "isActive": isActive,
    "adminVerified": adminVerified,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
  };
}

class RetailerUser {
  final String? docId;
  final bool? isDeleted;
  final String? id;
  final String? name;
  final String? phoneNumber;
  final num? lat;
  final num? lng;
  final bool? isVerified;
  final bool? isActive;
  final bool? isUnderProcessed;
  final String? image;
  final String? cnic;
  final String? cnicFront;
  final String? cnicBack;
  final String? distance;
  final String? shopAddress1;
  final String? shopAddress2;
  final String? shopCategory;
  final String? shopName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  RetailerUser({
    this.docId,
    this.isDeleted,
    this.id,
    this.name,
    this.phoneNumber,
    this.lat,
    this.lng,
    this.isVerified,
    this.isActive,
    this.isUnderProcessed,
    this.image,
    this.cnic,
    this.cnicFront,
    this.cnicBack,
    this.distance,
    this.shopAddress1,
    this.shopAddress2,
    this.shopCategory,
    this.shopName,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory RetailerUser.fromJson(Map<String, dynamic> json) => RetailerUser(
    docId: json["docId"],
    isDeleted: json["isDeleted"],
    id: json["_id"],
    name: json["name"],
    phoneNumber: json["phoneNumber"],
    lat: json["lat"],
    lng: json["lng"],
    isVerified: json["isVerified"],
    isActive: json["isActive"],
    isUnderProcessed: json["isUnderProcessed"],
    image: json["image"],
    cnic: json["cnic"],
    cnicFront: json["cnicFront"],
    cnicBack: json["cnicBack"],
    distance: json["distance"],
    shopAddress1: json["shopAddress1"],
    shopAddress2: json["shopAddress2"],
    shopCategory: json["shopCategory"],
    shopName: json["shopName"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    v: json["__v"],
  );

  Map<String, dynamic> toJson() => {
    "docId": docId,
    "isDeleted": isDeleted,
    "_id": id,
    "name": name,
    "phoneNumber": phoneNumber,
    "lat": lat,
    "lng": lng,
    "isVerified": isVerified,
    "isActive": isActive,
    "isUnderProcessed": isUnderProcessed,
    "image": image,
    "cnic": cnic,
    "cnicFront": cnicFront,
    "cnicBack": cnicBack,
    "distance": distance,
    "shopAddress1": shopAddress1,
    "shopAddress2": shopAddress2,
    "shopCategory": shopCategory,
    "shopName": shopName,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
  };
}

class SaleUser {
  final String? id;
  final String? name;
  final String? email;
  final String? password;
  final String? phone;
  final bool? isAdminVerified;
  final String? city;
  final bool? isActive;
  final String? image;
  final String? address;
  final String? cnic;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;
  final bool? isDeleted;
  final String? maritalStatus;

  SaleUser({
    this.id,
    this.name,
    this.email,
    this.password,
    this.phone,
    this.isAdminVerified,
    this.city,
    this.isActive,
    this.image,
    this.address,
    this.cnic,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.isDeleted,
    this.maritalStatus,
  });

  factory SaleUser.fromJson(Map<String, dynamic> json) => SaleUser(
    id: json["_id"],
    name: json["name"],
    email: json["email"],
    password: json["password"],
    phone: json["phone"],
    isAdminVerified: json["isAdminVerified"],
    city: json["city"],
    isActive: json["isActive"],
    image: json["image"],
    address: json["address"],
    cnic: json["cnic"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    v: json["__v"],
    isDeleted: json["isDeleted"],
    maritalStatus: json["maritalStatus"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "email": email,
    "password": password,
    "phone": phone,
    "isAdminVerified": isAdminVerified,
    "city": city,
    "isActive": isActive,
    "image": image,
    "address": address,
    "cnic": cnic,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
    "isDeleted": isDeleted,
    "maritalStatus": maritalStatus,
  };
}

class Status {
  final DateTime? date;
  final String? status;

  Status({
    this.date,
    this.status,
  });

  factory Status.fromJson(Map<String, dynamic> json) => Status(
    date: json["date"] == null ? null : DateTime.parse(json["date"]),
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "date": date?.toIso8601String(),
    "status": status,
  };
}