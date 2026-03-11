class InAppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String recipientId;
  final bool? forAdmin;
  final String? orderId; // Added orderId field
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? payload;

  InAppNotification( {
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.recipientId,
    this.orderId, // Optional orderId
    required this.createdAt,
    this.isRead = false,
    this.payload,
    this.forAdmin,
  });

  factory InAppNotification.fromMap(Map<String, dynamic> map) {
    return InAppNotification(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      recipientId: map['recipientId'] ?? '',
      orderId: map['orderId'],
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      isRead: map['isRead'] ?? false,
      payload: map['payload'],
      forAdmin: map['forAdmin'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'recipientId': recipientId,
      'orderId': orderId,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'payload': payload,
      'forAdmin': forAdmin
    };
  }
}
