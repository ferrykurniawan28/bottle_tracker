class DeviceEntity {
  final int id;
  final String uid;
  final bool isUsed;
  final DateTime createdAt;

  const DeviceEntity({
    required this.id,
    required this.uid,
    required this.isUsed,
    required this.createdAt,
  });
}
