class InventoryItem {
  String? id;
  String name;
  int quantity;
  double? price;
  String? description;
  String? createdAt;
  String? updatedAt;

  InventoryItem({
    this.id,
    required this.name,
    required this.quantity,
    this.price,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'quantity': quantity,
      'price': price,
      'description': description ?? '',
      'createdAt': createdAt ?? DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'],
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: map['price'] != null ? (map['price']).toDouble() : null,
      description: map['description'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }
}

class Inventory {
  String userId;
  String userName;
  List<InventoryItem> items;

  Inventory({
    required this.userId,
    required this.userName,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  factory Inventory.fromMap(Map<String, dynamic> map) {
    return Inventory(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      items: List<InventoryItem>.from(
        (map['items'] ?? []).map((item) => InventoryItem.fromMap(item)),
      ),
    );
  }
}
