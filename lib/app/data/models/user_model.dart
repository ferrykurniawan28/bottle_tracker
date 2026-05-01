import 'dart:convert';

class UserModel {
  final String id;
  final String email;
  final String password;
  final String name;
  final String uniqueCode;
  final String role;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.uniqueCode,
    this.role = 'user',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'password': password,
    'name': name,
    'uniqueCode': uniqueCode,
    'role': role,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    email: json['email'],
    password: json['password'],
    name: json['name'],
    uniqueCode: json['uniqueCode'],
    role: json['role'] ?? 'user',
    createdAt: DateTime.parse(json['createdAt']),
  );

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String str) =>
      UserModel.fromJson(jsonDecode(str));
}
