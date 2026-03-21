import 'package:cloud_firestore/cloud_firestore.dart';
import 'Shipment.dart';
import 'UserAccount.dart';

class DriverDeliveryData {
  final String driverName;
  final DateTime deliveryDate;
  final int parcelCount;
  final double totalCollections;
  final double price;
  final double driverPrice;
  final int delivered;
  final int returnedBeforeDelivery;
  final int returnedAfterDelivery;
  final int partiallyCollected;
  final int returned;
  final int totalTransportPeriod;
  List<Shipment> shipments;

  // Invoice related fields
  String? paymentMethod;
  String? documentNumber;
  String? notes;
  String? paymentImageUrl;
  String? pdfUrl;
  DateTime? paymentDate;
  String? id; // Used to reference the document ID in Firestore

  DriverDeliveryData({
    required this.driverName,
    required this.deliveryDate,
    required this.parcelCount,
    required this.totalCollections,
    required this.price,
    required this.driverPrice,
    required this.delivered,
    required this.returnedBeforeDelivery,
    required this.returnedAfterDelivery,
    required this.partiallyCollected,
    required this.returned,
    required this.totalTransportPeriod,
    this.shipments = const [],
    this.paymentMethod,
    this.documentNumber,
    this.notes,
    this.paymentImageUrl,
    this.pdfUrl,
    this.paymentDate,
    this.id,
  });

  // Calculate totals from shipments
  static DriverDeliveryData fromShipments(
      String driverName, List<Shipment> shipments) {
    int delivered = shipments.where((s) => s.status == 'تم توصيلها').length;

    int partiallyCollected = shipments.where((s) => s.status == 'تم تحصيلها بشكل جزئي').length;
    int returned = shipments.where((s) => s.status == 'تم إرجاعها').length;
    double totalCollections = shipments.fold(0, (sum, shipment) => sum + (shipment.driverCollection ?? 0));
    double totalPrice = shipments.where((s) => !(s.returnedAfterDelivery == false && s.status == 'تم إرجاعها')).fold(0, (sum, shipment) => sum + (shipment.deliveryCost ?? 0));



    return DriverDeliveryData(
      driverName: driverName,
      deliveryDate:
          DateTime.now(), // You might want to calculate this from shipments
      parcelCount: shipments.length,
      totalCollections: totalCollections,
      price: totalPrice,
      driverPrice: shipments.fold(0, (sum, shipment) => sum + (shipment.driverPrice ?? 0)),
      delivered: delivered,
      returnedBeforeDelivery:
          shipments.where((s) => s.returnedAfterDelivery == false).length,
      returnedAfterDelivery:
          shipments.where((s) => s.returnedAfterDelivery == true).length,
      partiallyCollected: partiallyCollected,
      returned: returned,
      totalTransportPeriod:
          0, // This might need to be calculated based on your business logic
      shipments: shipments,
    );
  }

  // Create from Map (JSON)
  factory DriverDeliveryData.fromMap(Map<String, dynamic> map,
      {String? docId}) {
    return DriverDeliveryData(
      id: docId,
      driverName: map['driverName'] ?? '',
      deliveryDate: DateTime.parse(
          map['deliveryDate'] ?? DateTime.now().toIso8601String()),
      parcelCount: map['parcelCount'] ?? 0,
      totalCollections: (map['totalCollections'] ?? 0.0).toDouble(),
      price: (map['price'] ?? 0.0).toDouble(),
      driverPrice: (map['driverPrice'] ?? 0.0).toDouble(),
      delivered: map['delivered'] ?? 0,
      returnedBeforeDelivery: map['returnedBeforeDelivery'] ?? 0,
      returnedAfterDelivery: map['returnedAfterDelivery'] ?? 0,
      partiallyCollected: map['partiallyCollected'] ?? 0,
      returned: map['returned'] ?? 0,
      totalTransportPeriod: map['totalTransportPeriod'] ?? 0,
      shipments: (map['shipments'] as List<dynamic>?)
              ?.map((shipmentMap) => Shipment.fromMap(shipmentMap))
              .toList() ??
          [],
      paymentMethod: map['paymentMethod'],
      documentNumber: map['documentNumber'],
      notes: map['notes'],
      paymentImageUrl: map['paymentImageUrl'],
      paymentDate: map['paymentDate'] != null
          ? (map['paymentDate'] as Timestamp).toDate()
          : null,
      pdfUrl: map['pdfUrl'],
    );
  }

  // Convert to Map (JSON)
  Map<String, dynamic> toMap() {
    return {
      'driverName': driverName,
      'deliveryDate': deliveryDate.toIso8601String(),
      'parcelCount': parcelCount,
      'totalCollections': totalCollections,
      'price': price,
      'driverPrice': driverPrice,
      'delivered': delivered,
      'returnedBeforeDelivery': returnedBeforeDelivery,
      'returnedAfterDelivery': returnedAfterDelivery,
      'partiallyCollected': partiallyCollected,
      'returned': returned,
      'totalTransportPeriod': totalTransportPeriod,
      'shipments': [],
      'paymentMethod': paymentMethod,
      'documentNumber': documentNumber,
      'notes': notes,
      'paymentImageUrl': paymentImageUrl,
      'paymentDate': FieldValue.serverTimestamp(),
      'pdfUrl': pdfUrl,
    };
  }

  // Copy with method for immutability
  DriverDeliveryData copyWith({
    String? driverName,
    DateTime? deliveryDate,
    int? parcelCount,
    double? totalCollections,
    double? price,
    double? driverPrice,
    int? delivered,
    int? returnedBeforeDelivery,
    int? returnedAfterDelivery,
    int? partiallyCollected,
    int? returned,
    int? totalTransportPeriod,
    List<Shipment>? shipments,
    String? paymentMethod,
    String? documentNumber,
    String? notes,
    String? paymentImageUrl,
    String? pdfUrl,
    DateTime? paymentDate,
    String? id,
  }) {
    return DriverDeliveryData(
      driverName: driverName ?? this.driverName,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      parcelCount: parcelCount ?? this.parcelCount,
      totalCollections: totalCollections ?? this.totalCollections,
      price: price ?? this.price,
      driverPrice: driverPrice ?? this.driverPrice,
        delivered: delivered ?? this.delivered,
      returnedBeforeDelivery:
          returnedBeforeDelivery ?? this.returnedBeforeDelivery,
      returnedAfterDelivery:
          returnedAfterDelivery ?? this.returnedAfterDelivery,
      partiallyCollected: partiallyCollected ?? this.partiallyCollected,
      returned: returned ?? this.returned,
      totalTransportPeriod: totalTransportPeriod ?? this.totalTransportPeriod,
      shipments: shipments ?? this.shipments,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      documentNumber: documentNumber ?? this.documentNumber,
      notes: notes ?? this.notes,
      paymentImageUrl: paymentImageUrl ?? this.paymentImageUrl,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      paymentDate: paymentDate ?? this.paymentDate,
      id: id ?? this.id,
    );
  }

  // Helper method to get shipments by status
  List<Shipment> getShipmentsByStatus(String status) {
    return shipments.where((shipment) => shipment.status == status).toList();
  }

  // Calculate total COD amount for specific status
  double getTotalCodAmountByStatus(String status) {
    return getShipmentsByStatus(status)
        .fold(0, (sum, shipment) => sum + (shipment.codAmount ?? 0));
  }

  // Get latest delivery date from shipments
  DateTime? getLatestDeliveryDate() {
    if (shipments.isEmpty) return null;

    DateTime? latest;
    for (var shipment in shipments) {
      if (shipment.deliveryDate != null) {
        if (latest == null || shipment.deliveryDate!.isAfter(latest)) {
          latest = shipment.deliveryDate;
        }
      }
    }
    return latest;
  }
}

// Extension to convert List<DriverDeliveryData> to List<UserAccount>
extension DriverDeliveryDataListExtension on List<DriverDeliveryData> {
  List<UserAccount> toUserAccounts() {
    // Group shipments by userId to create separate UserAccounts
    Map<String, List<Shipment>> shipmentsByUser = {};

    for (var deliveryData in this) {
      for (var shipment in deliveryData.shipments) {
        if (shipment.userId == null) continue; // Skip shipments with no userId
        shipmentsByUser[shipment.userId!] = [
          ...(shipmentsByUser[shipment.userId!] ?? []),
          shipment
        ];
      }
    }

    // Convert each group of shipments to a UserAccount
    return shipmentsByUser.values
        .map((shipments) => UserAccount.fromShipments(shipments))
        .toList();
  }
}
