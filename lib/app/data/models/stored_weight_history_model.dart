import 'dart:convert';
import '../../core/utils/datetime_utils.dart';

class StoredWeightHistoryModel {
  final int? id;
  final int storedId;
  final double weight;
  final DateTime? recordedAt;
  final String? note;
  bool isSynced;

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
        id: json['id'] is int
            ? json['id'] as int
            : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
        storedId: json['stored_id'] is int
            ? json['stored_id'] as int
            : (json['stored_id'] != null
                  ? int.parse(json['stored_id'].toString())
                  : 0),
        weight: _parseDouble(json['weight']),
        recordedAt: _parseDateTime(json['recorded_at'] ?? json['created_at']),
        note: json['note']?.toString(),
        isSynced: json['is_synced'] ?? false,
      );

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    if (v is Map) {
      // try to find a numeric value inside the map
      for (final val in v.values) {
        if (val is num) return val.toDouble();
        if (val is String) {
          final parsed = double.tryParse(val);
          if (parsed != null) return parsed;
        }
      }
    }
    return 0.0;
  }

  static DateTime? _parseDateTime(dynamic v) {
    if (v == null) return null;
    if (v is String) {
      try {
        return DateTime.parse(v).toUtcPlus7();
      } catch (_) {
        return null;
      }
    }
    if (v is DateTime) return v.toUtcPlus7();
    if (v is Map) {
      // sometimes time can be nested; try common keys
      if (v.containsKey('Time') && v['Time'] is String) {
        try {
          return DateTime.parse(v['Time']).toUtcPlus7();
        } catch (_) {}
      }
    }
    return null;
  }

  String toJsonString() => jsonEncode(toJson());
  factory StoredWeightHistoryModel.fromJsonString(String str) =>
      StoredWeightHistoryModel.fromJson(jsonDecode(str));
}
