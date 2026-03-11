enum SupplyOrderStatus { pending, accepted }

class SupplyItem {
  final String id; // Product ID
  final int quantity;
  final String? title; // Product title
  final double price;

  SupplyItem({
    required this.id,
    required this.quantity,
    this.title,
    this.price = 0.0,
  });

  factory SupplyItem.fromMap(Map<String, dynamic> map, String documentId) {
    return SupplyItem(
      id: documentId,
      quantity: map['quantity'] ?? 0,
      title: map['title'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quantity': quantity,
      'title': title,
      'price': price,
    };
  }
}

class SupplyOrder {
  final String id;
  final List<SupplyItem> items;
  final SupplyOrderStatus status;

  final String? userId;
  final String? userName;
  final String? driverId;
  final String? driverName;

  final String? createdAt;
  final String? updatedAt;

  SupplyOrder({
    this.createdAt,
    this.updatedAt,
    required this.id,
    required this.items,
    this.userId,
    this.userName,
    this.driverId,
    this.driverName,
    required this.status,
  });

  factory SupplyOrder.fromMap(Map<String, dynamic> map, String documentId) {
    return SupplyOrder(
      id: documentId,
      items: List<SupplyItem>.from(
        map['items'].map(
          (x) =>
              SupplyItem.fromMap(x as Map<String, dynamic>, x['id'] as String),
        ),
      ),
      userId: map['userId'],
      userName: map['userName'],
      driverId: map['driverId'],
      driverName: map['driverName'],
      status: SupplyOrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => SupplyOrderStatus.pending,
      ),
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items.map((x) => x.toMap()).toList(),
      'userId': userId,
      'userName': userName,
      'driverId': driverId,
      'driverName': driverName,
      'status': status.toString().split('.').last,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
