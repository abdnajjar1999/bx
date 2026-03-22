import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String? id;
  final String text;
  final String? imageUrl;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String recipientName;
  final String orderId;
  final String role; // 'سائق' (driver), 'محل' (shop), 'إدارة' (admin)
  final DateTime timestamp;

  ChatMessage({
    this.id,
    required this.text,
    this.imageUrl,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.recipientName,
    required this.orderId,
    required this.role,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, {String? id}) {
    return ChatMessage(
      id: id,
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      recipientId: map['recipientId'] ?? '',
      recipientName: map['recipientName'] ?? '',
      orderId: map['orderId'] ?? '',
      role: map['role'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'imageUrl': imageUrl,
      'senderId': senderId,
      'senderName': senderName,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'orderId': orderId,
      'role': role,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
