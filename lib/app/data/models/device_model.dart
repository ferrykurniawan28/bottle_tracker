import 'dart:convert';

class CatalogBottle {
  final String id;
  final String name;
  final String brand;
  final String category;
  final DateTime createdAt;

  CatalogBottle({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'brand': brand,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CatalogBottle.fromJson(Map<String, dynamic> json) => CatalogBottle(
    id: json['id'],
    name: json['name'],
    brand: json['brand'],
    category: json['category'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  CatalogBottle copyWith({
    String? id,
    String? name,
    String? brand,
    String? category,
  }) => CatalogBottle(
    id: id ?? this.id,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    category: category ?? this.category,
    createdAt: createdAt,
  );

  String toJsonString() => jsonEncode(toJson());
}

// import 'dart:convert';

// class DeviceModel {
//   final int? id;
//   final String? uid;
//   final DateTime? createdAt;

//   DeviceModel({this.id, this.uid, this.createdAt});

//   Map<String, dynamic> toJson() => {
//     if (id != null) 'id': id,
//     if (uid != null) 'uid': uid,
//     // Don't include createdAt - server will generate
//   };

//   factory DeviceModel.fromJson(Map<String, dynamic> json) => DeviceModel(
//     id: json['id'],
//     uid: json['uid'],
//     createdAt: json['created_at'] != null
//         ? DateTime.parse(json['created_at'])
//         : null,
//   );

//   String toJsonString() => jsonEncode(toJson());
//   factory DeviceModel.fromJsonString(String str) =>
//       DeviceModel.fromJson(jsonDecode(str));
// }
