import 'package:bottle_tracker/app/presentation/controllers/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationController = Get.find<NotificationController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (Get.isSnackbarOpen == false)
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () => notificationController.markAllAsRead(),
                  child: const Text('Mark all as read'),
                ),
                PopupMenuItem(
                  onTap: () =>
                      notificationController.getNotifications(refresh: true),
                  child: const Text('Refresh'),
                ),
              ],
            ),
        ],
      ),
      body: Obx(() {
        if (notificationController.isLoading.value &&
            notificationController.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (notificationController.notifications.isEmpty) {
          return const Center(child: Text('No notifications'));
        }

        return RefreshIndicator(
          onRefresh: () =>
              notificationController.getNotifications(refresh: true),
          child: ListView.builder(
            itemCount: notificationController.notifications.length + 1,
            itemBuilder: (context, index) {
              // return tile for each notification
              if (index < notificationController.notifications.length) {
                final notification =
                    notificationController.notifications[index];
                return NotificationTile(notification: notification);
              }
            },
          ),
        );
      }),
    );
  }
}
