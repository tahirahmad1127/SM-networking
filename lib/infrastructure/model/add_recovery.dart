import 'dart:convert';

/// ---------- AddRecoveryModel ----------

AddRecoveryModel addRecoveryModelFromJson(String str) =>
    AddRecoveryModel.fromJson(json.decode(str));

String addRecoveryModelToJson(AddRecoveryModel data) =>
    json.encode(data.toJson());

class AddRecoveryModel {
  final String retailerId;
  final String bankId;
  final double amount;
  final String? date;
  final String? details;
  final bool? isApproved;
  final String? imagePath;

  AddRecoveryModel({
    required this.retailerId,
    required this.bankId,
    required this.amount,
    this.date,
    this.details,
    this.isApproved = false,
    this.imagePath,
  });

  factory AddRecoveryModel.fromJson(Map<String, dynamic> json) =>
      AddRecoveryModel(
        retailerId: json["retailerId"],
        bankId: json["bankId"],
        amount: (json["amount"] ?? 0).toDouble(),
        date: json["date"],
        details: json["details"],
        isApproved: json["isApproved"] ?? false,
        imagePath: json["imagePath"],
      );

  Map<String, dynamic> toJson() => {
    "retailerId": retailerId,
    "bankId": bankId,
    "amount": amount,
    "date": date,
    "details": details,
    "isApproved": isApproved,
    "imagePath": imagePath,
  };
}

/// ---------- RecoveryModel ----------

RecoveryModel recoveryModelFromJson(String str) =>
    RecoveryModel.fromJson(json.decode(str));

String recoveryModelToJson(RecoveryModel data) =>
    json.encode(data.toJson());

class RecoveryModel {
  final String id;
  final String bankId;
  final double amount;
  final String? date;
  final String? details;
  final bool isApproved;
  final String? imageUrl;

  RecoveryModel({
    required this.id,
    required this.bankId,
    required this.amount,
    this.date,
    this.details,
    required this.isApproved,
    this.imageUrl,
  });

  factory RecoveryModel.fromJson(Map<String, dynamic> json) => RecoveryModel(
    id: json["_id"] ?? json["id"] ?? "",
    bankId: json["bankId"] ?? "",
    amount: (json["amount"] ?? 0).toDouble(),
    date: json["date"],
    details: json["details"],
    isApproved: json["isApproved"] ?? false,
    imageUrl: json["image"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "bankId": bankId,
    "amount": amount,
    "date": date,
    "details": details,
    "isApproved": isApproved,
    "image": imageUrl,
  };
}
