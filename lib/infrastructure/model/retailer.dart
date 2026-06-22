// To parse this JSON data, do
//
//     final retailersListingModel = retailersListingModelFromJson(jsonString);

import 'dart:convert';

RetailersListingModel retailersListingModelFromJson(String str) => RetailersListingModel.fromJson(json.decode(str));

String retailersListingModelToJson(RetailersListingModel data) => json.encode(data.toJson());
String retailersModelToJson(RetailerModel data) => json.encode(data.toJson());

class RetailersListingModel {
  final String? msg;
  final List<RetailerModel>? data;

  RetailersListingModel({
    this.msg,
    this.data,
  });

  factory RetailersListingModel.fromJson(Map<String, dynamic> json) => RetailersListingModel(
    msg: json["msg"],
    data: json["data"] == null ? [] : List<RetailerModel>.from(json["data"]!.map((x) => RetailerModel.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "msg": msg,
    "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
  };
}
RetailerModel retailerModelFromJson(String str) => RetailerModel.fromJson(json.decode(str));

String userModelToJson(RetailerModel data) => json.encode(data.toJson());

class RetailerModel {
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
  final num? distance;
  final String? shopAddress1;
  final bool? isDeleted;
  final String? shopAddress2;
  final String? shopCategory;
  final String? shopName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;
  final CityId? cityId;
  final String? docId;
  final SalesPersonId? salesPersonId;

  /// 'distributor' | 'wholesaler' | 'retailer' — set locally, not from API
  final String customerType;

  RetailerModel({
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
    this.isDeleted,
    this.shopAddress2,
    this.shopCategory,
    this.shopName,
    this.createdAt,
    this.updatedAt,
    this.v,
    this.cityId,
    this.docId,
    this.salesPersonId,
    this.customerType = 'distributor',
  });

  factory RetailerModel.fromJson(Map<String, dynamic> json) => RetailerModel(
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
    // distance: json["distance"],
    shopAddress1: json["shopAddress1"],
    isDeleted: json["isDeleted"],
    shopAddress2: json["shopAddress2"],
    shopCategory: json["shopCategory"],
    shopName: json["shopName"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    v: json["__v"],
    cityId: json["cityID"] == null ? null : CityId.fromJson(json["cityID"]),
    docId: json["docId"],
    salesPersonId: json["salesPersonID"] == null ? null : SalesPersonId.fromJson(json["salesPersonID"]),
    customerType: (json["customerType"] as String? ?? 'retailer').toLowerCase(),
  );

  Map<String, dynamic> toJson() => {
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
    // "distance": distance,
    "shopAddress1": shopAddress1,
    "isDeleted": isDeleted,
    "shopAddress2": shopAddress2,
    "shopCategory": shopCategory,
    "shopName": shopName,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
    "cityID": cityId?.toJson(),
    "docId": docId,
    "salesPersonID": salesPersonId?.toJson(),
    "customerType": customerType,
  };

  RetailerModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    num? lat,
    num? lng,
    bool? isVerified,
    bool? isActive,
    bool? isUnderProcessed,
    String? image,
    String? cnic,
    String? cnicFront,
    String? cnicBack,
    num? distance,
    String? shopAddress1,
    bool? isDeleted,
    String? shopAddress2,
    String? shopCategory,
    String? shopName,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? v,
    CityId? cityId,
    String? docId,
    SalesPersonId? salesPersonId,
    String? customerType,
  }) {
    return RetailerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      isUnderProcessed: isUnderProcessed ?? this.isUnderProcessed,
      image: image ?? this.image,
      cnic: cnic ?? this.cnic,
      cnicFront: cnicFront ?? this.cnicFront,
      cnicBack: cnicBack ?? this.cnicBack,
      distance: distance ?? this.distance,
      shopAddress1: shopAddress1 ?? this.shopAddress1,
      isDeleted: isDeleted ?? this.isDeleted,
      shopAddress2: shopAddress2 ?? this.shopAddress2,
      shopCategory: shopCategory ?? this.shopCategory,
      shopName: shopName ?? this.shopName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      v: v ?? this.v,
      cityId: cityId ?? this.cityId,
      docId: docId ?? this.docId,
      salesPersonId: salesPersonId ?? this.salesPersonId,
      customerType: customerType ?? this.customerType,
    );
  }
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

class SalesPersonId {
  final String? id;
  final String? name;
  final String? image;

  SalesPersonId({
    this.id,
    this.name,
    this.image,
  });

  factory SalesPersonId.fromJson(Map<String, dynamic> json) => SalesPersonId(
    id: json["_id"],
    name: json["name"],
    image: json["image"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "image": image,
  };
}