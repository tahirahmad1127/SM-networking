/// Minimal, self-contained model for the offline-mode product cache.
/// Deliberately separate from ProductModel — /api/offline/sync returns a
/// flat, much smaller shape ({success, count, data}, "id" not "_id", no
/// ctn/box sizing fields) that isn't compatible with ProductModel.fromJson.
class OfflineProductRef {
  final String id;
  final String englishName;

  OfflineProductRef({required this.id, required this.englishName});

  factory OfflineProductRef.fromJson(Map<String, dynamic> json) =>
      OfflineProductRef(
        id: json['id']?.toString() ?? '',
        englishName: json['englishName']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'englishName': englishName,
      };
}

class OfflineProductModel {
  final String id;
  final String name;
  final String englishTitle;
  final String urduTitle;
  final num price;
  // cortanSize = pieces per carton ("ctn"), piecesPerBox = pieces per box
  // ("box") — backend sends both the ProductModel-style names and short
  // ctn/box aliases with identical values; cortanSize/piecesPerBox is
  // preferred to stay consistent with the online ProductModel naming, with
  // ctn/box as a fallback in case either is ever missing.
  final num? cortanSize;
  final num? piecesPerBox;
  final OfflineProductRef? category;
  final OfflineProductRef? brand;
  final bool isActive;

  OfflineProductModel({
    required this.id,
    required this.name,
    required this.englishTitle,
    required this.urduTitle,
    required this.price,
    this.cortanSize,
    this.piecesPerBox,
    this.category,
    this.brand,
    required this.isActive,
  });

  factory OfflineProductModel.fromJson(Map<String, dynamic> json) =>
      OfflineProductModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        englishTitle: json['englishTitle']?.toString() ?? '',
        urduTitle: json['urduTitle']?.toString() ?? '',
        price: (json['price'] as num?) ?? 0,
        cortanSize: (json['cortanSize'] as num?) ?? (json['ctn'] as num?),
        piecesPerBox: (json['piecesPerBox'] as num?) ?? (json['box'] as num?),
        category: json['category'] == null
            ? null
            : OfflineProductRef.fromJson(
                json['category'] as Map<String, dynamic>),
        brand: json['brand'] == null
            ? null
            : OfflineProductRef.fromJson(json['brand'] as Map<String, dynamic>),
        isActive: json['isActive'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'englishTitle': englishTitle,
        'urduTitle': urduTitle,
        'price': price,
        'cortanSize': cortanSize,
        'piecesPerBox': piecesPerBox,
        'category': category?.toJson(),
        'brand': brand?.toJson(),
        'isActive': isActive,
      };
}
