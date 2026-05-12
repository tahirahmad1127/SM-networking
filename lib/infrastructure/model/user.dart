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
  final List<Distributor>? distributors;

  UserModel({
    this.token,
    this.user,
    this.role,
    this.distributors,
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
  );

  Map<String, dynamic> toJson() => {
    "token": token,
    "user": user?.toJson(),
    "role": role,
    "distributors": distributors?.map((e) => e.toJson()).toList(),
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
}