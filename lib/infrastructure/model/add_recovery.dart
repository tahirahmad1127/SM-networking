import 'dart:convert';

String recoveryModelRefId(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  if (v is Map) {
    return v['_id']?.toString() ?? v['id']?.toString() ?? '';
  }
  return '';
}

String recoveryModelRefName(dynamic v) {
  if (v is Map) return v['name']?.toString() ?? '';
  return '';
}

/// ---------- AddRecoveryModel (Request) ----------

AddRecoveryModel addRecoveryModelFromJson(String str) =>
    AddRecoveryModel.fromJson(json.decode(str));

String addRecoveryModelToJson(AddRecoveryModel data) =>
    json.encode(data.toJson());

class AddRecoveryModel {
  final String distributionName;
  final String zone;
  final String town;
  final String tsm;

  /// recordedBy = same as tsm (the logged-in user's ID).
  /// Sent explicitly because the API stores it as a separate field.
  final String recordedBy;

  final double amount;
  final String? date;
  final String bankName;
  final String branchCode;
  final String paymentMode;
  final String beneficiaryAccountNumber;
  final String beneficiaryAccountName;
  final String beneficiaryBankName;
  final String? receiptPic;

  /// "distributor" | "wholesaler" | "retailer"
  final String paymentType;

  /// Reserved for future use; send as empty string by default.
  final String customerType;

  AddRecoveryModel({
    required this.distributionName,
    required this.zone,
    required this.town,
    required this.tsm,
    String? recordedBy,
    required this.amount,
    this.date,
    required this.bankName,
    required this.branchCode,
    required this.paymentMode,
    required this.beneficiaryAccountNumber,
    required this.beneficiaryAccountName,
    required this.beneficiaryBankName,
    this.receiptPic,
    this.paymentType = 'distributor',
    this.customerType = '',
  }) : recordedBy = recordedBy ?? tsm;

  factory AddRecoveryModel.fromJson(Map<String, dynamic> json) =>
      AddRecoveryModel(
        distributionName: json["distributionName"] ?? "",
        zone: json["zone"] ?? "",
        town: json["town"] ?? "",
        tsm: json["tsm"] ?? "",
        recordedBy: json["recordedBy"] ?? json["tsm"] ?? "",
        amount: (json["amount"] ?? 0).toDouble(),
        date: json["date"],
        bankName: json["bankName"] ?? "",
        branchCode: json["branchCode"] ?? "",
        paymentMode: json["paymentMode"] ?? "",
        beneficiaryAccountNumber: json["beneficiaryAccountNumber"] ?? "",
        beneficiaryAccountName: json["beneficiaryAccountName"] ?? "",
        beneficiaryBankName: json["beneficiaryBankName"] ?? "",
        receiptPic: json["receiptPic"],
        paymentType: json["paymentType"] ?? "distributor",
        customerType: json["customerType"] ?? "",
      );

  Map<String, dynamic> toJson() => {
    "distributionName": distributionName,
    "zone": zone,
    "town": town,
    "tsm": tsm,
    "recordedBy": recordedBy,
    "amount": amount,
    "date": date,
    "bankName": bankName,
    "branchCode": branchCode,
    "paymentMode": paymentMode,
    "beneficiaryAccountNumber": beneficiaryAccountNumber,
    "beneficiaryAccountName": beneficiaryAccountName,
    "beneficiaryBankName": beneficiaryBankName,
    "paymentType": paymentType,
    "customerType": customerType,
    if (receiptPic != null && receiptPic!.isNotEmpty) "receiptPic": receiptPic,
  };
}

/// ---------- RecoveryModel (Response) ----------

RecoveryModel recoveryModelFromJson(String str) =>
    RecoveryModel.fromJson(json.decode(str));

String recoveryModelToJson(RecoveryModel data) =>
    json.encode(data.toJson());

class RecoveryModel {
  final String id;
  final String srNo;
  final String distributionName;
  final String zone;
  final String zoneName;
  final String town;
  final String townName;
  final double amount;
  final String tsm;
  final String tsmName;

  /// The user who recorded the payment (equals tsm in current API responses).
  final String recordedBy;

  final String bankName;
  final String branchCode;
  final String paymentMode;
  final String beneficiaryAccountNumber;
  final String beneficiaryAccountName;
  final String beneficiaryBankName;
  final String? receiptPic;
  final String? beneficiaryAccount;
  final String? date;
  final bool isDeleted;
  final String? createdAt;
  final String? updatedAt;
  final String paymentType;
  final String customerType;

  RecoveryModel({
    required this.id,
    required this.srNo,
    required this.distributionName,
    required this.zone,
    required this.zoneName,
    required this.town,
    required this.townName,
    required this.amount,
    required this.tsm,
    required this.tsmName,
    required this.recordedBy,
    required this.bankName,
    required this.branchCode,
    required this.paymentMode,
    required this.beneficiaryAccountNumber,
    required this.beneficiaryAccountName,
    required this.beneficiaryBankName,
    this.receiptPic,
    this.beneficiaryAccount,
    this.date,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
    this.paymentType = 'distributor',
    this.customerType = '',
  });

  factory RecoveryModel.fromJson(Map<String, dynamic> json) => RecoveryModel(
    id: json["_id"] ?? json["id"] ?? "",
    srNo: json["srNo"] ?? "",
    distributionName: json["distributionName"] ?? "",
    zone: recoveryModelRefId(json["zone"]),
    zoneName:
    (json["zoneName"] ?? recoveryModelRefName(json["zone"]))?.toString() ??
        "",
    town: recoveryModelRefId(json["town"]),
    townName:
    (json["townName"] ?? recoveryModelRefName(json["town"]))?.toString() ??
        "",
    amount: (json["amount"] ?? 0).toDouble(),
    tsm: recoveryModelRefId(json["tsm"]),
    tsmName:
    (json["tsmName"] ?? recoveryModelRefName(json["tsm"]))?.toString() ??
        "",
    recordedBy: recoveryModelRefId(json["recordedBy"]),
    bankName: json["bankName"] ?? "",
    branchCode: json["branchCode"] ?? "",
    paymentMode: json["paymentMode"] ?? "",
    beneficiaryAccountNumber: json["beneficiaryAccountNumber"] ?? "",
    beneficiaryAccountName: json["beneficiaryAccountName"] ?? "",
    beneficiaryBankName: json["beneficiaryBankName"] ?? "",
    receiptPic: json["receiptPic"],
    beneficiaryAccount: json["beneficiaryAccount"],
    date: json["date"],
    isDeleted: json["isDeleted"] ?? false,
    createdAt: json["createdAt"],
    updatedAt: json["updatedAt"],
    paymentType: json["paymentType"] ?? "distributor",
    customerType: json["customerType"] ?? "",
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "srNo": srNo,
    "distributionName": distributionName,
    "zone": zone,
    "zoneName": zoneName,
    "town": town,
    "townName": townName,
    "amount": amount,
    "tsm": tsm,
    "tsmName": tsmName,
    "recordedBy": recordedBy,
    "bankName": bankName,
    "branchCode": branchCode,
    "paymentMode": paymentMode,
    "beneficiaryAccountNumber": beneficiaryAccountNumber,
    "beneficiaryAccountName": beneficiaryAccountName,
    "beneficiaryBankName": beneficiaryBankName,
    "receiptPic": receiptPic,
    "beneficiaryAccount": beneficiaryAccount,
    "date": date,
    "isDeleted": isDeleted,
    "createdAt": createdAt,
    "updatedAt": updatedAt,
    "paymentType": paymentType,
    "customerType": customerType,
  };
}

class RecoveryListingModel {
  final List<RecoveryModel> data;
  final int total;
  final int page;
  final int totalPages;

  RecoveryListingModel({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory RecoveryListingModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic v, [int def = 0]) {
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? def;
    }

    final raw = json["data"];
    final list = <RecoveryModel>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          list.add(RecoveryModel.fromJson(e));
        } else if (e is Map) {
          list.add(RecoveryModel.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    return RecoveryListingModel(
      data: list,
      total: toInt(json["total"]),
      page: toInt(json["page"], 1),
      totalPages: toInt(json["totalPages"], 1),
    );
  }
}