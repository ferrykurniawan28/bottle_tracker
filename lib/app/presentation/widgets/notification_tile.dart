import 'package:bottle_tracker/app/domain/entities/notification_entity.dart';
import 'package:bottle_tracker/app/presentation/controllers/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationTile extends StatelessWidget {
  final NotificationEntity notification;

  const NotificationTile({super.key, required this.notification});

  Color _getActionColor(String actionType) {
    switch (actionType) {
      case 'pickup_confirmation':
        return Colors.blue;
      case 'usage_check':
        return Colors.orange;
      case 'admin_alert':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getActionLabel(String actionType) {
    switch (actionType) {
      case 'pickup_confirmation':
        return 'Pickup Confirmation';
      case 'usage_check':
        return 'Usage Check';
      case 'admin_alert':
        return 'Admin Alert';
      default:
        return 'Notification';
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationController = Get.find<NotificationController>();
    final actionColor = _getActionColor(notification.actionType);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Container(width: 4, color: actionColor),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.body),
            const SizedBox(height: 4),
            Chip(
              label: Text(_getActionLabel(notification.actionType)),
              backgroundColor: actionColor.withOpacity(0.2),
              labelStyle: TextStyle(color: actionColor, fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () =>
              notificationController.deleteNotification(notification.id),
        ),
        isThreeLine: true,
        onTap: notification.actionType == 'pickup_confirmation'
            ? () =>
                  _showPickupConfirmationDialog(context, notificationController)
            : notification.actionType == 'usage_check'
            ? () => _showUsageCheckDialog(context, notificationController)
            : () => notificationController.markAsRead(notification.id),
      ),
    );
  }

  void _showPickupConfirmationDialog(
    BuildContext context,
    NotificationController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pickup Confirmation'),
        content: const Text('Did you pick up this bottle?'),
        actions: [
          TextButton(
            onPressed: () {
              controller.confirmPickupNo(notification.id);
              Get.back();
            },
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () {
              controller.confirmPickupYes(notification.id);
              Get.back();
            },
            child: const Text('YES', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _showUsageCheckDialog(
    BuildContext context,
    NotificationController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Still Using?'),
        content: const Text('Are you still using this bottle?'),
        actions: [
          TextButton(
            onPressed: () {
              controller.confirmDoneUsing(notification.id);
              Get.back();
            },
            child: const Text('Done'),
          ),
          TextButton(
            onPressed: () {
              controller.confirmStillUsing(notification.id);
              Get.back();
            },
            child: const Text(
              'Still Using',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
