class NotificationEntity {
  final int id;
  final int userId;
  final String title;
  final String body;
  final String actionType;
  final String actionStatus;
  final int? relatedStoredId;
  final DateTime? expiresAt;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? confirmedAt;

  NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.actionType,
    required this.actionStatus,
    this.relatedStoredId,
    this.expiresAt,
    this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.confirmedAt,
  });
}
