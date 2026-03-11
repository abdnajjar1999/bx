import '../main.dart';
import 'Shipment.dart';

class UserAccount {
  final String id;
  final String client;
  final String? location;
  final String? branch;
  final int totalParcels;
  final int returnedParcels;
  final int totalShipments;
  final int assignedOrders;
  final String? userType;
  final String? paymentType;
  final double servicesFees;
  final double insuranceFees;
  final double taxFees;
  final double totalAmount;
  final List<Shipment> shipments;

  // Payment related fields
  String? paymentMethod;
  String? documentNumber;
  String? notes;
  String? paymentImageUrl;
  String? pdfUrl;
  DateTime? paymentDate;
  bool? haveInventoryItems;

  UserAccount({
    required this.id,
    required this.client,
    this.location,
    this.branch,
    required this.totalParcels,
    required this.returnedParcels,
    required this.totalShipments,
    required this.assignedOrders,
    this.userType,
    this.paymentType,
    required this.servicesFees,
    required this.insuranceFees,
    required this.taxFees,
    required this.totalAmount,
    required this.shipments,
    this.paymentMethod,
    this.documentNumber,
    this.notes,
    this.paymentImageUrl,
    this.paymentDate,
    this.pdfUrl,
    this.haveInventoryItems,
  });

  // Create UserAccount from a list of shipments
  factory UserAccount.fromShipments(List<Shipment> shipments) {
    if (shipments.isEmpty) {
      throw Exception('Cannot create UserAccount from empty shipments list');
    }

    final firstShipment = shipments.first;
    bool haveInventoryItems = false;

    // Calculate totals
    double finalTotalAmount = 0;
    double servicesFees = 0;
    for (var shipment in shipments) {
      if (shipment.selectedItems != null) {
        haveInventoryItems = true;
      }
      if (shipment.status == "تم إرجاعها") {
        if (shipment.getMoneyFromUserPalance == true) {
          servicesFees += shipment.deliveryCost ?? 0.0;
        }
      } else {
        finalTotalAmount += shipment.codAmount ?? 0.0;
        servicesFees += shipment.deliveryCost ?? 0.0;
      }
    }
    double taxFees = servicesFees * 0.15; // Assuming 15% tax on services

    return UserAccount(
      id: firstShipment.userId ?? '',
      client: firstShipment.username ?? '',
      location: firstShipment.city,
      branch: KcompanyName,
      totalParcels: shipments.fold(
          0, (sum, shipment) => sum + (shipment.parcelCount ?? 0)),
      returnedParcels: shipments
          .where((shipment) => shipment.status == 'تم إرجاعها')
          .fold(0, (sum, shipment) => sum + (shipment.parcelCount ?? 0)),
      totalShipments: shipments.length,
      assignedOrders:
          shipments.where((shipment) => shipment.driverId != null).length,
      userType: 'Regular',
      paymentType: firstShipment.paymentMethod,
      servicesFees: servicesFees,
      insuranceFees: 0.0,
      taxFees: taxFees,
      totalAmount: finalTotalAmount,
      shipments: shipments,
      haveInventoryItems: haveInventoryItems,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client': client,
      'location': location,
      'branch': branch,
      'totalParcels': totalParcels,
      'returnedParcels': returnedParcels,
      'totalShipments': totalShipments,
      'assignedOrders': assignedOrders,
      'userType': userType,
      'paymentType': paymentType,
      'servicesFees': servicesFees,
      'insuranceFees': insuranceFees,
      'taxFees': taxFees,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'documentNumber': documentNumber,
      'notes': notes,
      'paymentImageUrl': paymentImageUrl,
      'paymentDate': paymentDate?.toIso8601String(),
      'pdfUrl': pdfUrl,
    };
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      id: map['id'] ?? '',
      client: map['client'] ?? '',
      location: map['location'],
      branch: map['branch'],
      totalParcels: map['totalParcels'] ?? 0,
      returnedParcels: map['returnedParcels'] ?? 0,
      totalShipments: map['totalShipments'] ?? 0,
      assignedOrders: map['assignedOrders'] ?? 0,
      userType: map['userType'],
      paymentType: map['paymentType'],
      servicesFees: (map['servicesFees'] ?? 0.0).toDouble(),
      insuranceFees: (map['insuranceFees'] ?? 0.0).toDouble(),
      taxFees: (map['taxFees'] ?? 0.0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      shipments: [],
      paymentMethod: map['paymentMethod'],
      documentNumber: map['documentNumber'],
      notes: map['notes'],
      paymentImageUrl: map['paymentImageUrl'],
      paymentDate: map['paymentDate'] != null
          ? DateTime.parse(map['paymentDate'])
          : null,
      pdfUrl: map['pdfUrl'],
    );
  }

  double getAmountToPay() {
    return totalAmount - servicesFees;
  }
}
