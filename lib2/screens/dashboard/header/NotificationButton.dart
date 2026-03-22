import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/appProvider.dart';
import '../../../models/InAppNotification.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {
                showNotificationOverlay(context);
              },
            ),
            if (appProvider.unreadNotifications > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    '${appProvider.unreadNotifications}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void showNotificationOverlay(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final position = button.localToGlobal(Offset.zero);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Stack(
            children: [
              Positioned(
                top: position.dy + 50,
                left: 20,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 350,
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const NotificationOverlay(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      barrierColor: Colors.transparent,
    );
  }
}

class NotificationOverlay extends StatelessWidget {
  const NotificationOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'الإشعارات',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => appProvider.markAllAsRead(),
                        child: const Text('تحديد الكل كمقروء'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => appProvider.deleteAllNotifications(),
                        child: const Text('حذف الكل'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: appProvider.notifications.isEmpty
                  ? const Center(child: Text('لا توجد إشعارات'))
                  : ListView.builder(
                itemCount: appProvider.notifications.length,
                itemBuilder: (context, index) {
                  final notification = appProvider.notifications[index];
                  return NotificationItem(notification: notification);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class NotificationItem extends StatelessWidget {
  final InAppNotification notification;

  const NotificationItem({
    Key? key,
    required this.notification,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    return Container(
      color: notification.isRead ? Colors.white : Color(0xFF4F46E5).withOpacity(0.1),
      child: ListTile(
        title: Text(notification.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!notification.isRead)
              IconButton(
                icon: const Icon(Icons.mark_email_read),
                onPressed: () => appProvider.markAsRead(notification.id),
                tooltip: 'تحديد كمقروء',
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => appProvider.deleteNotification(notification.id),
              tooltip: 'حذف',
            ),
          ],
        ),
        onTap: () {
          if (!notification.isRead) {
            appProvider.markAsRead(notification.id);
          }
          // Handle notification tap - maybe navigate to related content
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}