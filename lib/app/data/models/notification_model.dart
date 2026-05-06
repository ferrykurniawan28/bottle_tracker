import '../../core/utils/datetime_utils.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  NotificationModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.body,
    required super.actionType,
    required super.actionStatus,
    super.relatedStoredId,
    super.expiresAt,
    super.data,
    required super.isRead,
    required super.createdAt,
    super.readAt,
    super.confirmedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      actionType: json['action_type'] ?? 'info',
      actionStatus: json['action_status'] ?? 'pending',
      relatedStoredId: json['related_stored_id'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at']).toUtcPlus7()
          : null,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ).toUtcPlus7(),
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at']).toUtcPlus7()
          : null,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at']).toUtcPlus7()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'action_type': actionType,
      'action_status': actionStatus,
      'related_stored_id': relatedStoredId,
      'expires_at': expiresAt?.toIso8601String(),
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
    String? actionType,
    String? actionStatus,
    int? relatedStoredId,
    DateTime? expiresAt,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? confirmedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      actionType: actionType ?? this.actionType,
      actionStatus: actionStatus ?? this.actionStatus,
      relatedStoredId: relatedStoredId ?? this.relatedStoredId,
      expiresAt: expiresAt ?? this.expiresAt,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }
}
