import 'dart:convert';

class StoredWeightHistoryModel {
  final int? id;
  final int storedId; // Foreign key to stored
  final double weight;
  final DateTime? recordedAt;
  final String? note;
  bool isSynced; // Track if locally stored entry is synced

  StoredWeightHistoryModel({
    this.id,
    required this.storedId,
    required this.weight,
    this.recordedAt,
    this.note,
    this.isSynced = false,
  });

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'stored_id': storedId,
    'weight': weight,
    if (recordedAt != null) 'recorded_at': recordedAt!.toIso8601String(),
    if (note != null) 'note': note,
    // isSynced is local-only field
  };

  // For sending to server (without local-only fields)
  Map<String, dynamic> toApiJson() => {
    'stored_id': storedId,
    'weight': weight,
    if (note != null) 'note': note,
    // recorded_at will be set by server if not provided
    if (recordedAt != null) 'recorded_at': recordedAt!.toIso8601String(),
  };

  factory StoredWeightHistoryModel.fromJson(Map<String, dynamic> json) =>
      StoredWeightHistoryModel(
        id: json['id'],
        storedId: json['stored_id'],
        weight: (json['weight'] as num).toDouble(),
        recordedAt: json['recorded_at'] != null
            ? DateTime.parse(json['recorded_at'])
            : null,
        note: json['note'],
        isSynced: json['is_synced'] ?? false,
      );

  String toJsonString() => jsonEncode(toJson());
  factory StoredWeightHistoryModel.fromJsonString(String str) =>
      StoredWeightHistoryModel.fromJson(jsonDecode(str));
}
