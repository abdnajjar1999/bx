import 'package:cloud_firestore/cloud_firestore.dart';

class Order1 {
  String profileImageUrl;
  String status;
  DateTime timestamp;
  String userId;
  String username;
  String customerName;
  String price;
  String notes;
  String region;
  String orderNumber;
  String orderSpecifications;
  bool isDriverAssigned;
  double deliveryCost;
  bool isCompleted;
  String? driverName;
  String? phone;
  String location;
  String weight;
  double COD;
  String PaymentMethod;
  Order1({
    required this.status,
    this.phone,
    required this.profileImageUrl,
    required this.timestamp,
    required this.userId,
    required this.username,
    required this.customerName,
    required this.price,
    required this.notes,
    required this.region,
    required this.orderNumber,
    required this.orderSpecifications,
    required this.isDriverAssigned,
    required this.deliveryCost,
    this.isCompleted = false,
    this.driverName,
    required this.location,
    required this.weight,
    required this.COD,
    required this.PaymentMethod,
  });

  // Create an Order1 object from Firestore data (fromMap)
  factory Order1.fromMap(Map<String, dynamic> data) {
    return Order1(
      PaymentMethod: data['طريقة الدفع'] ?? '',
      COD: data['COD']??0.0,
      status: data['status'] ?? 'nuUl',
      profileImageUrl: data['profileImageUrl'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['userId'] ?? '',
      username: data['username'] ?? '',
      customerName: data['اسم العميل'] ?? '',
      price: data['السعر'].toString() ?? '',
      notes: data['الملاحظات'] ?? '',
      region: data['المنطقة'] ?? '',
      orderNumber: data['رقم الطلب'] ?? '',
      orderSpecifications: data['مواصفات الطلب'] ?? '',
      isDriverAssigned: data['isDriverAssigned'] ?? false,
      deliveryCost: data['deliveryCost']?.toDouble() ?? 0.0,
      isCompleted: data['isCompleted'] ?? false,
      driverName: data['driverName'],
      phone: data['رقم الهاتف'],
      location: data['رابط خريطة جوجل'] ?? '',
      weight: data['الوزن'] ?? '',
    );
  }

  // Convert the Order1 object to a map to store it in Firestore (toMap)
  Map<String, dynamic> toMap() {
    return {
      "طريقة الدفع": PaymentMethod,
      "COD": COD,
      'profileImageUrl': profileImageUrl,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
      'username': username,
      'اسم العميل': customerName,
      'السعر': price,
      'الملاحظات': notes,
      'المنطقة': region,
      'رقم الطلب': orderNumber,
      'مواصفات الطلب': orderSpecifications,
      'isDriverAssigned': isDriverAssigned,
      'deliveryCost': deliveryCost,
      'isCompleted': isCompleted,
      'driverName': driverName,
      'رقم الهاتف': phone,
      'رابط خريطة جوجل': location,
      'الوزن': weight,
    };
  }
}
