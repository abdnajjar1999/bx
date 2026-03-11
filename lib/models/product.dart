class Product {
  final String id;
  final String title;
  final String category;
  final String description;
  final String imageUrl;
  final double price;
  // final double rating;
  final int calories;
  final int prepTimeMinutes;
  final int stock;

  Product({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.price,
    // this.rating = 0.0,
    this.calories = 0,
    this.prepTimeMinutes = 0,
    this.stock = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'calories': calories,
      'prepTimeMinutes': prepTimeMinutes,
      'stock': stock,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, String documentId) {
    return Product(
      id: documentId,
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      calories: map['calories']?.toInt() ?? 0,
      prepTimeMinutes: map['prepTimeMinutes']?.toInt() ?? 0,
      stock: map['stock']?.toInt() ?? 0,
    );
  }

  // Sample data for menu items (cleaned up for merchandise focus)
  static List<Product> getSampleItems() {
    return [
      Product(
        id: '1',
        title: 'Smartphone X',
        category: 'Electronics',
        description:
            'Latest model with high-resolution camera and fast processor.',
        imageUrl:
            'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9',
        price: 999.00,
        stock: 50,
      ),
      Product(
        id: '2',
        title: 'Running Shoes',
        category: 'Sports',
        description: 'Comfortable running shoes for daily workouts.',
        imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff',
        price: 89.99,
        stock: 200,
      ),
      Product(
        id: '3',
        title: 'Cotton T-Shirt',
        category: 'Fashion',
        description: '100% cotton t-shirt, available in various sizes.',
        imageUrl:
            'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab',
        price: 19.99,
        stock: 500,
      ),
    ];
  }

  // Find a menu item by id
  static Product? findById(String id) {
    try {
      return getSampleItems().firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }
}
