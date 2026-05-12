class BankModel {
  final String id;
  final String name;

  BankModel({required this.id, required this.name});

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['bankName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'bankName': name,
    };
  }
}

class BanksListModel {
  final List<BankModel> banks;

  BanksListModel({required this.banks});

  factory BanksListModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? [];
    return BanksListModel(
      banks: data.map((bank) => BankModel.fromJson(bank)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': banks.map((bank) => bank.toJson()).toList(),
    };
  }
}
