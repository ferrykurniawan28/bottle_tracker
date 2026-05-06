import 'dart:convert';
import '../../core/utils/datetime_utils.dart';

class StoredModel {
  final int id;
  final int deviceId;
  final int ownerId;
  final double? weight;
  final String bottleName;
  final String brand;
  final String? category;
  final String status;
  final DateTime? createdAt;

  StoredModel({
    required this.id,
    required this.deviceId,
    required this.ownerId,
    this.weight,
    required this.bottleName,
    required this.brand,
    this.category,
    this.createdAt,
    this.status = 'active',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'device_id': deviceId,
    'owner_id': ownerId,
    'weight': weight,
    'bottle_name': bottleName,
    'brand': brand,
    'category': category,
    'created_at': createdAt?.toIso8601String(),
    'status': status,
  };

  factory StoredModel.fromJson(Map<String, dynamic> json) => StoredModel(
    id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
    deviceId: json['device_id'] is int
        ? json['device_id']
        : int.parse(json['device_id'].toString()),
    ownerId: json['owner_id'] is int
        ? json['owner_id']
        : int.parse(json['owner_id'].toString()),
    weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
    bottleName: json['bottle_name'].toString(),
    brand: json['brand'].toString(),
    category: json['category']?.toString(),
    status: json['status']?.toString() ?? 'active',
    createdAt: json['created_at'] is String
        ? DateTime.parse(json['created_at']).toUtcPlus7()
        : (json['created_at'] as DateTime?)?.toUtcPlus7(),
  );

  StoredModel copyWith({
    int? id,
    int? deviceId,
    int? ownerId,
    double? weight,
    String? bottleName,
    String? brand,
    String? category,
    DateTime? createdAt,
    String? status,
  }) => StoredModel(
    id: id ?? this.id,
    deviceId: deviceId ?? this.deviceId,
    ownerId: ownerId ?? this.ownerId,
    weight: weight ?? this.weight,
    bottleName: bottleName ?? this.bottleName,
    brand: brand ?? this.brand,
    category: category ?? this.category,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
  );

  String toJsonString() => jsonEncode(toJson());

  factory StoredModel.fromJsonString(String str) =>
      StoredModel.fromJson(jsonDecode(str));
}

enum StoredCategory { whiskey, vodka, tequila, liqueur }

String storedCategoryToString(StoredCategory category) {
  switch (category) {
    case StoredCategory.whiskey:
      return 'whiskey';
    case StoredCategory.vodka:
      return 'vodka';
    case StoredCategory.tequila:
      return 'tequila';
    case StoredCategory.liqueur:
      return 'liqueur';
  }
}
