// To parse this JSON data, do
//
//     final userModel = userModelFromJson(jsonString);

import 'dart:convert';

UserModel userModelFromJson(String str) => UserModel.fromJson(json.decode(str));

String userModelToJson(UserModel data) => json.encode(data.toJson());

class UserModel {
  final String? token;
  final User? user;
  final String? role;
  // TSM / warehouseManager: flat distributors list (unchanged)
  final List<Distributor>? distributors;
  // orderBooker: separate wholesalers and retailers lists
  final List<Wholesaler>? wholesalers;
  final List<Wholesaler>? retailers;
  final int? totalWholesalers;
  final int? totalRetailers;
  // orderBookers: returned only for the warehouseManager role
  final List<OrderBooker>? orderBookers;
  final int? totalOrderBookers;

  UserModel({
    this.token,
    this.user,
    this.role,
    this.distributors,
    this.wholesalers,
    this.retailers,
    this.totalWholesalers,
    this.totalRetailers,
    this.orderBookers,
    this.totalOrderBookers,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    token: json["token"],
    user: json["user"] == null ? null : User.fromJson(json["user"]),
    role: json["role"],
    distributors: json["distributors"] == null
        ? null
        : (json["distributors"] as List)
        .map((e) => Distributor.fromJson(e))
        .toList(),
    wholesalers: json["wholesalers"] == null
        ? null
        : (json["wholesalers"] as List)
        .map((e) => Wholesaler.fromJson(e))
        .toList(),
    retailers: json["retailers"] == null
        ? null
        : (json["retailers"] as List)
        .map((e) => Wholesaler.fromJson(e))
        .toList(),
    totalWholesalers: json["totalWholesalers"],
    totalRetailers: json["totalRetailers"],
    orderBookers: json["orderBookers"] == null
        ? null
        : (json["orderBookers"] as List)
        .map((e) => OrderBooker.fromJson(e))
        .toList(),
    totalOrderBookers: json["totalOrderBookers"],
  );

  Map<String, dynamic> toJson() => {
    "token": token,
    "user": user?.toJson(),
    "role": role,
    "distributors": distributors?.map((e) => e.toJson()).toList(),
    "wholesalers": wholesalers?.map((e) => e.toJson()).toList(),
    "retailers": retailers?.map((e) => e.toJson()).toList(),
    "totalWholesalers": totalWholesalers,
    "totalRetailers": totalRetailers,
    "orderBookers": orderBookers?.map((e) => e.toJson()).toList(),
    "totalOrderBookers": totalOrderBookers,
  };
}

// ─── Logged-in user ──────────────────────────────────────────────────────────

class User {
  final String? id;
  final String? salesId;
  final String? name;
  final String? email;
  final String? password;
  final String? phone;
  final bool? isAdminVerified;
  final bool? isDeleted;
  final bool? isActive;
  final String? image;
  final String? address;
  final String? cnic;
  final String? maritalStatus;
  final String? zone;
  // town comes as List<String> (IDs) for the logged-in user
  final List<String>? town;
  final String? coordinator;
  final String? tsm;
  final String? distributor;
  // Only populated when `distributor` arrives as a nested {_id, name} object
  // rather than a bare ObjectId string — mirrors OrderBookerDistributorRef,
  // which the warehouse-manager/:tsmId/order-bookers endpoint already
  // returns populated this way. sale-user/login doesn't populate it yet
  // (see attendance/layout/body.dart's assigned-distributor banner).
  final String? distributorName;
  final num? basicSalary;
  final num? allowanceDistance;
  final num? dailyAllowance;
  final num? miscellaneousAllowance;
  final num? mobileAllowance;
  final String? incentiveStructure;
  final String? checkInTime;
  final String? checkOutTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  User({
    this.id,
    this.salesId,
    this.name,
    this.email,
    this.password,
    this.phone,
    this.isAdminVerified,
    this.isDeleted,
    this.isActive,
    this.image,
    this.address,
    this.cnic,
    this.maritalStatus,
    this.zone,
    this.town,
    this.coordinator,
    this.tsm,
    this.distributor,
    this.distributorName,
    this.basicSalary,
    this.allowanceDistance,
    this.dailyAllowance,
    this.miscellaneousAllowance,
    this.mobileAllowance,
    this.incentiveStructure,
    this.checkInTime,
    this.checkOutTime,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["_id"],
    salesId: json["salesId"],
    name: json["name"],
    email: json["email"],
    password: json["password"],
    phone: json["phone"],
    isAdminVerified: json["isAdminVerified"],
    isDeleted: json["isDeleted"],
    isActive: json["isActive"],
    image: json["image"],
    address: json["address"],
    cnic: json["cnic"],
    maritalStatus: json["maritalStatus"],
    // zone: plain string ID or nested object {_id, name}
    zone: json["zone"] == null
        ? null
        : (json["zone"] is String
        ? json["zone"] as String
        : json["zone"]["_id"] as String),
    // town: always normalised to List<String> of IDs
    // can arrive as List<String>, List<{_id,name}>, single String, or single object
    town: json["town"] == null
        ? null
        : (json["town"] is List
        ? (json["town"] as List)
        .map((e) => e is String ? e : e["_id"] as String)
        .toList()
        : [
      json["town"] is String
          ? json["town"] as String
          : json["town"]["_id"] as String
    ]),
    coordinator: json["coordinator"] == null
        ? null
        : (json["coordinator"] is String
        ? json["coordinator"] as String
        : json["coordinator"]["_id"] as String),
    tsm: json["tsm"] == null
        ? null
        : (json["tsm"] is String
        ? json["tsm"] as String
        : json["tsm"]["_id"] as String),
    distributor: json["distributor"] is String ? json["distributor"] : json["distributor"]?["_id"],
    distributorName: json["distributor"] is Map
        ? (json["distributor"]["distributionName"] ?? json["distributor"]["name"])
        : null,
    basicSalary: json["basicSalary"],
    allowanceDistance: json["allowanceDistance"],
    dailyAllowance: json["dailyAllowance"],
    miscellaneousAllowance: json["miscellaneousAllowance"],
    mobileAllowance: json["mobileAllowance"],
    incentiveStructure: json["incentiveStructure"],
    checkInTime: json["checkInTime"],
    checkOutTime: json["checkOutTime"],
    createdAt: json["createdAt"] == null
        ? null
        : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null
        ? null
        : DateTime.parse(json["updatedAt"]),
    v: json["__v"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "salesId": salesId,
    "name": name,
    "email": email,
    "password": password,
    "phone": phone,
    "isAdminVerified": isAdminVerified,
    "isDeleted": isDeleted,
    "isActive": isActive,
    "image": image,
    "address": address,
    "cnic": cnic,
    "maritalStatus": maritalStatus,
    "zone": zone,
    "town": town,
    "coordinator": coordinator,
    "tsm": tsm,
    "distributor": distributor,
    "distributorName": distributorName,
    "basicSalary": basicSalary,
    "allowanceDistance": allowanceDistance,
    "dailyAllowance": dailyAllowance,
    "miscellaneousAllowance": miscellaneousAllowance,
    "mobileAllowance": mobileAllowance,
    "incentiveStructure": incentiveStructure,
    "checkInTime": checkInTime,
    "checkOutTime": checkOutTime,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
  };

  /// Used by splash_screen/layout/body.dart to carry [distributorName]
  /// forward across the post-login `getUserByID` refresh, in case that
  /// endpoint's `distributor` field isn't populated the same way
  /// sale-user/login's is.
  User copyWith({String? distributorName}) => User(
    id: id,
    salesId: salesId,
    name: name,
    email: email,
    password: password,
    phone: phone,
    isAdminVerified: isAdminVerified,
    isDeleted: isDeleted,
    isActive: isActive,
    image: image,
    address: address,
    cnic: cnic,
    maritalStatus: maritalStatus,
    zone: zone,
    town: town,
    coordinator: coordinator,
    tsm: tsm,
    distributor: distributor,
    distributorName: distributorName ?? this.distributorName,
    basicSalary: basicSalary,
    allowanceDistance: allowanceDistance,
    dailyAllowance: dailyAllowance,
    miscellaneousAllowance: miscellaneousAllowance,
    mobileAllowance: mobileAllowance,
    incentiveStructure: incentiveStructure,
    checkInTime: checkInTime,
    checkOutTime: checkOutTime,
    createdAt: createdAt,
    updatedAt: updatedAt,
    v: v,
  );
}

// ─── Distributor (returned only for TSM role) ────────────────────────────────

class DistributorLocation {
  final double? lat;
  final double? lng;

  DistributorLocation({this.lat, this.lng});

  factory DistributorLocation.fromJson(Map<String, dynamic> json) =>
      DistributorLocation(
        lat: json["lat"] == null ? null : (json["lat"] as num).toDouble(),
        lng: json["lng"] == null ? null : (json["lng"] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {"lat": lat, "lng": lng};
}

class DistributorRef {
  final String? id;
  final String? name;

  DistributorRef({this.id, this.name});

  factory DistributorRef.fromJson(Map<String, dynamic> json) => DistributorRef(
    id: json["_id"],
    name: json["name"],
  );

  Map<String, dynamic> toJson() => {"_id": id, "name": name};
}

class Distributor {
  final String? id;
  final String? salesId;
  final String? name;
  final String? email;
  final String? phone;
  final String? password;
  final bool? isAdminVerified;
  final bool? isDeleted;
  final bool? isActive;
  final String? image;
  final String? securityChequeImage;
  final String? address;
  final String? cnic;
  final String? maritalStatus;
  final String? target;
  final String? distributionName;
  final String? billingAddress;
  final String? cityTab;
  final String? province;
  final String? postalCode;
  final String? country;
  final String? ntn;
  final String? stn;
  final List<dynamic>? assignedArea;
  final num? basicSalary;
  final num? allowanceDistance;
  final num? dailyAllowance;
  final num? miscellaneousAllowance;
  final String? checkInTime;
  final String? checkOutTime;
  final String? coordinator;
  // tsm, zone, town are populated objects {_id, name} in distributor list
  final DistributorRef? tsm;
  final DistributorRef? zone;
  final DistributorRef? town;
  final DistributorLocation? shopLocation;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  Distributor({
    this.id,
    this.salesId,
    this.name,
    this.email,
    this.phone,
    this.password,
    this.isAdminVerified,
    this.isDeleted,
    this.isActive,
    this.image,
    this.securityChequeImage,
    this.address,
    this.cnic,
    this.maritalStatus,
    this.target,
    this.distributionName,
    this.billingAddress,
    this.cityTab,
    this.province,
    this.postalCode,
    this.country,
    this.ntn,
    this.stn,
    this.assignedArea,
    this.basicSalary,
    this.allowanceDistance,
    this.dailyAllowance,
    this.miscellaneousAllowance,
    this.checkInTime,
    this.checkOutTime,
    this.coordinator,
    this.tsm,
    this.zone,
    this.town,
    this.shopLocation,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Distributor.fromJson(Map<String, dynamic> json) => Distributor(
    id: json["id"] ?? json["_id"],
    salesId: json["salesId"],
    name: json["name"],
    email: json["email"],
    phone: json["phone"],
    password: json["password"],
    isAdminVerified: json["isAdminVerified"],
    isDeleted: json["isDeleted"],
    isActive: json["isActive"],
    image: json["image"],
    securityChequeImage: json["securityChequeImage"],
    address: json["address"],
    cnic: json["cnic"],
    maritalStatus: json["maritalStatus"],
    target: json["target"],
    distributionName: json["distributionName"],
    billingAddress: json["billingAddress"],
    cityTab: json["cityTab"],
    province: json["province"],
    postalCode: json["postalCode"],
    country: json["country"],
    ntn: json["ntn"],
    stn: json["stn"],
    assignedArea: json["assignedArea"],
    basicSalary: json["basicSalary"],
    allowanceDistance: json["allowanceDistance"],
    dailyAllowance: json["dailyAllowance"],
    miscellaneousAllowance: json["miscellaneousAllowance"],
    checkInTime: json["checkInTime"],
    checkOutTime: json["checkOutTime"],
    coordinator: json["coordinator"] == null
        ? null
        : (json["coordinator"] is String
        ? json["coordinator"] as String
        : json["coordinator"]["_id"] as String),
    tsm: json["tsm"] == null ? null : DistributorRef.fromJson(json["tsm"]),
    zone: json["zone"] == null
        ? null
        : DistributorRef.fromJson(json["zone"]),
    town: json["town"] == null
        ? null
        : DistributorRef.fromJson(json["town"]),
    shopLocation: json["shopLocation"] == null
        ? null
        : DistributorLocation.fromJson(json["shopLocation"]),
    createdAt: json["createdAt"] == null
        ? null
        : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null
        ? null
        : DateTime.parse(json["updatedAt"]),
    v: json["__v"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "salesId": salesId,
    "name": name,
    "email": email,
    "phone": phone,
    "password": password,
    "isAdminVerified": isAdminVerified,
    "isDeleted": isDeleted,
    "isActive": isActive,
    "image": image,
    "securityChequeImage": securityChequeImage,
    "address": address,
    "cnic": cnic,
    "maritalStatus": maritalStatus,
    "target": target,
    "distributionName": distributionName,
    "billingAddress": billingAddress,
    "cityTab": cityTab,
    "province": province,
    "postalCode": postalCode,
    "country": country,
    "ntn": ntn,
    "stn": stn,
    "assignedArea": assignedArea,
    "basicSalary": basicSalary,
    "allowanceDistance": allowanceDistance,
    "dailyAllowance": dailyAllowance,
    "miscellaneousAllowance": miscellaneousAllowance,
    "checkInTime": checkInTime,
    "checkOutTime": checkOutTime,
    "coordinator": coordinator,
    "tsm": tsm?.toJson(),
    "zone": zone?.toJson(),
    "town": town?.toJson(),
    "shopLocation": shopLocation?.toJson(),
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
  };

  Distributor copyWith({DistributorLocation? shopLocation}) {
    return Distributor(
      id: id,
      salesId: salesId,
      name: name,
      email: email,
      phone: phone,
      password: password,
      isAdminVerified: isAdminVerified,
      isDeleted: isDeleted,
      isActive: isActive,
      image: image,
      securityChequeImage: securityChequeImage,
      address: address,
      cnic: cnic,
      maritalStatus: maritalStatus,
      target: target,
      distributionName: distributionName,
      billingAddress: billingAddress,
      cityTab: cityTab,
      province: province,
      postalCode: postalCode,
      country: country,
      ntn: ntn,
      stn: stn,
      assignedArea: assignedArea,
      basicSalary: basicSalary,
      allowanceDistance: allowanceDistance,
      dailyAllowance: dailyAllowance,
      miscellaneousAllowance: miscellaneousAllowance,
      checkInTime: checkInTime,
      checkOutTime: checkOutTime,
      coordinator: coordinator,
      tsm: tsm,
      zone: zone,
      town: town,
      shopLocation: shopLocation ?? this.shopLocation,
      createdAt: createdAt,
      updatedAt: updatedAt,
      v: v,
    );
  }
}

// ─── Wholesaler / Retailer (returned for orderBooker AND warehouseManager) ────

class Wholesaler {
  final String? id;
  final String? name;
  final String? contacts; // phone equivalent
  final String? address;
  final String? pic;      // image equivalent
  final DistributorRef? zone;
  final DistributorRef? town;
  final bool? isActive;
  final bool? isAdminVerified;
  final bool? isDeleted;
  final DistributorLocation? addressFromGoogle;
  // Shop location — may be added by backend later; kept nullable
  final DistributorLocation? shopLocation;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  Wholesaler({
    this.id,
    this.name,
    this.contacts,
    this.address,
    this.pic,
    this.zone,
    this.town,
    this.isActive,
    this.isAdminVerified,
    this.isDeleted,
    this.addressFromGoogle,
    this.shopLocation,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory Wholesaler.fromJson(Map<String, dynamic> json) => Wholesaler(
    id: json["_id"] ?? json["id"],
    name: json["name"],
    contacts: json["contacts"],
    address: json["address"],
    pic: json["pic"],
    zone: json["zone"] == null
        ? null
        : (json["zone"] is String
        ? DistributorRef(id: json["zone"])
        : DistributorRef.fromJson(json["zone"])),
    town: json["town"] == null
        ? null
        : (json["town"] is String
        ? DistributorRef(id: json["town"])
        : DistributorRef.fromJson(json["town"])),
    isActive: json["isActive"],
    isAdminVerified: json["isAdminVerified"],
    isDeleted: json["isDeleted"],
    addressFromGoogle: json["addressFromGoogle"] == null || json["addressFromGoogle"] is! Map
        ? null
        : DistributorLocation.fromJson(json["addressFromGoogle"]),
    shopLocation: json["shopLocation"] == null
        ? null
        : DistributorLocation.fromJson(json["shopLocation"]),
    createdAt: json["createdAt"] == null
        ? null
        : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null
        ? null
        : DateTime.parse(json["updatedAt"]),
    v: json["__v"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "contacts": contacts,
    "address": address,
    "pic": pic,
    "zone": zone?.toJson(),
    "town": town?.toJson(),
    "isActive": isActive,
    "isAdminVerified": isAdminVerified,
    "isDeleted": isDeleted,
    "addressFromGoogle": addressFromGoogle?.toJson(),
    "shopLocation": shopLocation?.toJson(),
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
  };

  Wholesaler copyWith({DistributorLocation? shopLocation, DistributorLocation? addressFromGoogle, String? address}) => Wholesaler(
    id: id,
    name: name,
    contacts: contacts,
    address: address ?? this.address,
    pic: pic,
    zone: zone,
    town: town,
    isActive: isActive,
    isAdminVerified: isAdminVerified,
    isDeleted: isDeleted,
    addressFromGoogle: addressFromGoogle ?? this.addressFromGoogle,
    shopLocation: shopLocation ?? this.shopLocation,
    createdAt: createdAt,
    updatedAt: updatedAt,
    v: v,
  );
}
// ─── OrderBooker (returned only for the warehouseManager role) ──────────────
// Each warehouseManager's login response includes the list of orderBookers
// working under them, so this can be displayed straight from the in-memory
// UserModel without an extra API call.

class OrderBookerDistributorRef {
  final String? id;
  final String? name;
  final String? distributionName;

  OrderBookerDistributorRef({this.id, this.name, this.distributionName});

  factory OrderBookerDistributorRef.fromJson(Map<String, dynamic> json) =>
      OrderBookerDistributorRef(
        id: json["_id"] ?? json["id"],
        name: json["name"],
        distributionName: json["distributionName"],
      );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "name": name,
    "distributionName": distributionName,
  };
}

class OrderBooker {
  final String? id;
  final String? salesId;
  final String? name;
  final String? email;
  final String? phone;
  final bool? isAdminVerified;
  final bool? isDeleted;
  final bool? isActive;
  final String? image;
  final String? address;
  final String? cnic;
  final String? maritalStatus;
  final DistributorRef? zone;
  final DistributorRef? town;
  final String? coordinator;
  final DistributorRef? tsm;
  final OrderBookerDistributorRef? distributor;
  final num? basicSalary;
  final num? allowanceDistance;
  final num? dailyAllowance;
  final num? miscellaneousAllowance;
  final num? mobileAllowance;
  final String? incentiveStructure;
  final String? checkInTime;
  final String? checkOutTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  OrderBooker({
    this.id,
    this.salesId,
    this.name,
    this.email,
    this.phone,
    this.isAdminVerified,
    this.isDeleted,
    this.isActive,
    this.image,
    this.address,
    this.cnic,
    this.maritalStatus,
    this.zone,
    this.town,
    this.coordinator,
    this.tsm,
    this.distributor,
    this.basicSalary,
    this.allowanceDistance,
    this.dailyAllowance,
    this.miscellaneousAllowance,
    this.mobileAllowance,
    this.incentiveStructure,
    this.checkInTime,
    this.checkOutTime,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  factory OrderBooker.fromJson(Map<String, dynamic> json) => OrderBooker(
    id: json["_id"] ?? json["id"],
    salesId: json["salesId"],
    name: json["name"],
    email: json["email"],
    phone: json["phone"],
    isAdminVerified: json["isAdminVerified"],
    isDeleted: json["isDeleted"],
    isActive: json["isActive"],
    image: json["image"],
    address: json["address"],
    cnic: json["cnic"],
    maritalStatus: json["maritalStatus"],
    zone: json["zone"] == null
        ? null
        : (json["zone"] is String
        ? DistributorRef(id: json["zone"])
        : DistributorRef.fromJson(json["zone"])),
    town: json["town"] == null
        ? null
        : (json["town"] is String
        ? DistributorRef(id: json["town"])
        : DistributorRef.fromJson(json["town"])),
    coordinator: json["coordinator"] == null
        ? null
        : (json["coordinator"] is String
        ? json["coordinator"] as String
        : json["coordinator"]["_id"] as String),
    tsm: json["tsm"] == null
        ? null
        : (json["tsm"] is String
        ? DistributorRef(id: json["tsm"])
        : DistributorRef.fromJson(json["tsm"])),
    distributor: json["distributor"] == null
        ? null
        : OrderBookerDistributorRef.fromJson(json["distributor"]),
    basicSalary: json["basicSalary"],
    allowanceDistance: json["allowanceDistance"],
    dailyAllowance: json["dailyAllowance"],
    miscellaneousAllowance: json["miscellaneousAllowance"],
    mobileAllowance: json["mobileAllowance"],
    incentiveStructure: json["incentiveStructure"],
    checkInTime: json["checkInTime"],
    checkOutTime: json["checkOutTime"],
    createdAt: json["createdAt"] == null
        ? null
        : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null
        ? null
        : DateTime.parse(json["updatedAt"]),
    v: json["__v"],
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "salesId": salesId,
    "name": name,
    "email": email,
    "phone": phone,
    "isAdminVerified": isAdminVerified,
    "isDeleted": isDeleted,
    "isActive": isActive,
    "image": image,
    "address": address,
    "cnic": cnic,
    "maritalStatus": maritalStatus,
    "zone": zone?.toJson(),
    "town": town?.toJson(),
    "coordinator": coordinator,
    "tsm": tsm?.toJson(),
    "distributor": distributor?.toJson(),
    "basicSalary": basicSalary,
    "allowanceDistance": allowanceDistance,
    "dailyAllowance": dailyAllowance,
    "miscellaneousAllowance": miscellaneousAllowance,
    "mobileAllowance": mobileAllowance,
    "incentiveStructure": incentiveStructure,
    "checkInTime": checkInTime,
    "checkOutTime": checkOutTime,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
  };
}