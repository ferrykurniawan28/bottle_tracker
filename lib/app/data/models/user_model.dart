import 'dart:convert';
import '../../core/utils/datetime_utils.dart';

class UserModel {
  final String id;
  final String email;
  final String password;
  final String name;
  final String uniqueCode;
  final String role;
  final DateTime createdAt;
  String? fcmToken;

  UserModel({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.uniqueCode,
    this.role = 'user',
    DateTime? createdAt,
    this.fcmToken,
  }) : createdAt = createdAt ?? DateTime.now();

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue is DateTime) return dateValue.toUtcPlus7();
    if (dateValue is String) {
      // Try standard ISO8601 format first
      try {
        return DateTime.parse(dateValue).toUtcPlus7();
      } catch (_) {
        // Handle Go's time format: "2026-05-01 04:06:26.31428 +0000 +0000"
        try {
          // Extract the date and time part (before the first +)
          final datePart = dateValue.split('+').first.trim();
          // Replace space with T to make it ISO8601 compatible
          final isoFormat = '${datePart}Z';
          return DateTime.parse(isoFormat).toUtcPlus7();
        } catch (_) {
          // Fallback to now
          return DateTime.now();
        }
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'password': password,
    'name': name,
    'uniqueCode': uniqueCode,
    'role': role,
    'createdAt': createdAt.toIso8601String(),
    'fcmToken': fcmToken,
  };

  factory UserModel.fromJson(Map<String, dynamic> json, void param1) =>
      UserModel(
        id: json['id'].toString(),
        email: json['email'],
        password: json['password'] ?? '',
        name: json['name'] ?? json['username'] ?? '',
        uniqueCode: (json['uniqueCode'] ?? json['uid'] ?? '').toString(),
        role: json['role'] ?? 'user',
        createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
        fcmToken: json['fcmToken'] ?? json['fcm_token'],
      );

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String str) =>
      UserModel.fromJson(jsonDecode(str), null);
}
