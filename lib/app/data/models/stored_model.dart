import 'dart:convert';

class BottleModel {
  final String id;
  final String userId;
  final String name;
  final String brand;
  final String category;
  final double weightGrams;
  final double? currentWeightGrams;
  final String? notes;
  final DateTime storedAt;
  final bool isReturned;

  BottleModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.brand,
    required this.category,
    required this.weightGrams,
    this.currentWeightGrams,
    this.notes,
    DateTime? storedAt,
    this.isReturned = false,
  }) : storedAt = storedAt ?? DateTime.now();

  double get weightDifference =>
      currentWeightGrams != null ? weightGrams - currentWeightGrams! : 0;

  bool get hasBeenTouched =>
      currentWeightGrams != null && currentWeightGrams != weightGrams;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'brand': brand,
    'category': category,
    'weightGrams': weightGrams,
    'currentWeightGrams': currentWeightGrams,
    'notes': notes,
    'storedAt': storedAt.toIso8601String(),
    'isReturned': isReturned,
  };

  factory BottleModel.fromJson(Map<String, dynamic> json) => BottleModel(
    id: json['id'],
    userId: json['userId'],
    name: json['name'],
    brand: json['brand'],
    category: json['category'],
    weightGrams: (json['weightGrams'] as num).toDouble(),
    currentWeightGrams: json['currentWeightGrams'] != null
        ? (json['currentWeightGrams'] as num).toDouble()
        : null,
    notes: json['notes'],
    storedAt: DateTime.parse(json['storedAt']),
    isReturned: json['isReturned'] ?? false,
  );

  BottleModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? brand,
    String? category,
    double? weightGrams,
    double? currentWeightGrams,
    String? notes,
    DateTime? storedAt,
    bool? isReturned,
  }) => BottleModel(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    brand: brand ?? this.brand,
    category: category ?? this.category,
    weightGrams: weightGrams ?? this.weightGrams,
    currentWeightGrams: currentWeightGrams ?? this.currentWeightGrams,
    notes: notes ?? this.notes,
    storedAt: storedAt ?? this.storedAt,
    isReturned: isReturned ?? this.isReturned,
  );

  String toJsonString() => jsonEncode(toJson());
  factory BottleModel.fromJsonString(String str) =>
      BottleModel.fromJson(jsonDecode(str));
}

// import 'dart:convert';

// class StoredModel {
//   final int? id;
//   final int deviceId; // Foreign key to device
//   final int ownerId; // Foreign key to users
//   final double? weight; // Current weight (from history)
//   final String bottleName; // Changed from 'name' to 'bottle_name'
//   final String brand;
//   final String? category;
//   final DateTime? createdAt;

//   StoredModel({
//     this.id,
//     required this.deviceId,
//     required this.ownerId,
//     this.weight,
//     required this.bottleName,
//     required this.brand,
//     this.category,
//     this.createdAt,
//   });

//   Map<String, dynamic> toJson() => {
//     if (id != null) 'id': id,
//     'device_id': deviceId,
//     'owner_id': ownerId,
//     if (weight != null) 'weight': weight,
//     'bottle_name': bottleName,
//     'brand': brand,
//     if (category != null) 'category': category,
//     // Don't include createdAt - server will generate
//   };

//   factory StoredModel.fromJson(Map<String, dynamic> json) => StoredModel(
//     id: json['id'],
//     deviceId: json['device_id'],
//     ownerId: json['owner_id'],
//     weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
//     bottleName: json['bottle_name'],
//     brand: json['brand'],
//     category: json['category'],
//     createdAt: json['created_at'] != null
//         ? DateTime.parse(json['created_at'])
//         : null,
//   );

//   StoredModel copyWith({
//     int? id,
//     int? deviceId,
//     int? ownerId,
//     double? weight,
//     String? bottleName,
//     String? brand,
//     String? category,
//     DateTime? createdAt,
//   }) => StoredModel(
//     id: id ?? this.id,
//     deviceId: deviceId ?? this.deviceId,
//     ownerId: ownerId ?? this.ownerId,
//     weight: weight ?? this.weight,
//     bottleName: bottleName ?? this.bottleName,
//     brand: brand ?? this.brand,
//     category: category ?? this.category,
//     createdAt: createdAt ?? this.createdAt,
//   );

//   String toJsonString() => jsonEncode(toJson());
//   factory StoredModel.fromJsonString(String str) =>
//       StoredModel.fromJson(jsonDecode(str));
// }
