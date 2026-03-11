import 'package:good_line_delivery/main.dart';
import 'package:good_line_delivery/models/customer.dart';
import 'package:good_line_delivery/shared/appProvider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../models/InAppNotification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // String userId=FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _notifications =>
      _firestore.collection('notifications');

  // Get notifications by orderId
  Stream<List<InAppNotification>> getNotificationsByOrder(String orderId) {
    return _notifications
        .where('forAdmin', isEqualTo: true)
        .where('orderId', isEqualTo: orderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                InAppNotification.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get notifications for current user
  Stream<List<InAppNotification>> getNotificationsForUser(String recipientId) {
    return _notifications
        .where('recipientId', isEqualTo: recipientId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                InAppNotification.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Create a new notification with orderId
  Future<void> createNotification({
    required String title,
    required String message,
    required String type,
    required String recipientId,
    String? orderId,
    Map<String, dynamic>? payload,
    bool forAdmin = true,
  }) {
    final notification = InAppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      recipientId: recipientId,
      orderId: orderId,
      createdAt: DateTime.now(),
      payload: payload,
      forAdmin: forAdmin,
    );
    return _notifications.doc(notification.id).set(notification.toMap());
  }

  // Delete notifications by orderId
  Future<void> deleteNotificationsByOrder(
      String orderId, List<InAppNotification> notifications) async {
    final batch = _firestore.batch();

    List<InAppNotification> orderNotifications = notifications
        .where((notification) => notification.orderId == orderId)
        .toList();

    for (var notification in orderNotifications) {
      batch.delete(_notifications.doc(notification.id));
    }

    return batch.commit();
  }

  Stream<List<InAppNotification>> getNotifications() {
    return _notifications
        .where('forAdmin', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) =>
                InAppNotification.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) {
    return _notifications.doc(notificationId).update({'isRead': true});
  }

  // Mark all notifications as read
  Future<void> markAllAsRead(List<InAppNotification> notifications) async {
    final batch = _firestore.batch();
    List<InAppNotification> unreadNotifications =
        notifications.where((notification) => !notification.isRead).toList();
    for (var notification in unreadNotifications) {
      batch.update(_notifications.doc(notification.id), {'isRead': true});
    }

    return batch.commit();
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) {
    return _notifications.doc(notificationId).delete();
  }

  // Delete all notifications for user
  Future<void> deleteAllNotifications(
      List<InAppNotification> notifications) async {
    final batch = _firestore.batch();
    for (var notification in notifications) {
      batch.delete(_notifications.doc(notification.id));
    }

    return batch.commit();
  }

  sendWhatsAppMessage(String phoneNumber, String message) async {
    final response = await http.get(
      Uri.parse(
        'https://api.textmebot.com/send.php?recipient=$phoneNumber&apikey=$whatsappKey&text=$message',
      ),
    );

    print("response: ${response.body}");
  }
}
