import 'dart:convert';
import '../../core/utils/datetime_utils.dart';
import '../../domain/entities/device_entity.dart';

class DeviceModel extends DeviceEntity {
  const DeviceModel({
    required super.id,
    required super.uid,
    required super.isUsed,
    required super.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': uid,
    'is_used': isUsed,
    'created_at': createdAt.toIso8601String(),
  };

  factory DeviceModel.fromJson(Map<String, dynamic> json) => DeviceModel(
    id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
    uid: json['uid'].toString(),
    isUsed: json['is_used'] as bool? ?? false,
    createdAt: json['created_at'] is String
        ? DateTime.parse(json['created_at']).toUtcPlus7()
        : (json['created_at'] as DateTime).toUtcPlus7(),
  );

  DeviceModel copyWith({
    int? id,
    String? uid,
    bool? isUsed,
    DateTime? createdAt,
  }) => DeviceModel(
    id: id ?? this.id,
    uid: uid ?? this.uid,
    isUsed: isUsed ?? this.isUsed,
    createdAt: createdAt ?? this.createdAt,
  );

  String toJsonString() => jsonEncode(toJson());

  factory DeviceModel.fromJsonString(String str) =>
      DeviceModel.fromJson(jsonDecode(str));
}
