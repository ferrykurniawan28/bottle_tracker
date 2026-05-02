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
          Obx(
            () => notificationController.unreadCount.value > 0
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          notificationController.unreadCount.value.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
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
              if (index == notificationController.notifications.length) {
                if (!notificationController.isLoading.value) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: notificationController.loadMoreNotifications,
                      child: const Text('Load More'),
                    ),
                  );
                }
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                );
              }

              return NotificationTile(
                notification: notificationController.notifications[index],
              );
            },
          ),
        );
      }),
    );
  }
}
