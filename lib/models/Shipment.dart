import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:good_line_delivery/models/Shelf.dart';
import '../models/PriceCalculators.dart';
import 'package:firebase_core/firebase_core.dart';

import '../shared/constants.dart';
import 'Driver.dart';

class ShipmentLog {
  final DateTime date;
  final String text;
  final String? status;
  final String? userName;

  ShipmentLog({
    required this.date,
    required this.text,
    required this.status,
    this.userName,
  });

  factory ShipmentLog.fromMap(Map<String, dynamic> map) {
    return ShipmentLog(
      date: Shipment._parseDate(map['date']),
      text: map['text'] ?? '',
      status: map['status'],
      userName: map['userName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'text': text,
      'status': status,
      'userName': userName,
    };
  }
}

class PackageAttributes {
  final bool isFragile;
  final bool needsPackaging;
  final bool hasDangerousMaterials;
  final bool isNonOpenable;
  final bool canBeFolded;
  final bool measurementForbidden;

  PackageAttributes({
    required this.isFragile,
    required this.needsPackaging,
    required this.hasDangerousMaterials,
    required this.isNonOpenable,
    required this.canBeFolded,
    required this.measurementForbidden,
  });

  factory PackageAttributes.fromMap(Map<String, dynamic> map) {
    return PackageAttributes(
      isFragile: map['isFragile'] ?? false,
      needsPackaging: map['needsPackaging'] ?? false,
      hasDangerousMaterials: map['hasDangerousMaterials'] ?? false,
      isNonOpenable: map['isNonOpenable'] ?? false,
      canBeFolded: map['canBeFolded'] ?? false,
      measurementForbidden: map['measurementForbidden'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isFragile': isFragile,
      'needsPackaging': needsPackaging,
      'hasDangerousMaterials': hasDangerousMaterials,
      'isNonOpenable': isNonOpenable,
      'canBeFolded': canBeFolded,
      'measurementForbidden': measurementForbidden,
    };
  }
}

enum CashPossession { receiver, driver, branch, customer }

// cashPossession extension
extension CashPossessionExtension on CashPossession {
  String get nameAr {
    switch (this) {
      case CashPossession.receiver:
        return 'المستلم';
      case CashPossession.driver:
        return 'السائق';
      case CashPossession.branch:
        return 'الفرع';
      case CashPossession.customer:
        return 'العميل';
    }
  }
}

//enum orderPossession
enum OrderPossession {
  receiver,
  driverFetching,
  driverShipping,
  driverReturning,
  branch,
  customer
}

// orderPossession extension
extension OrderPossessionExtension on OrderPossession {
  String get nameAr {
    switch (this) {
      case OrderPossession.receiver:
        return 'المستلم';
      case OrderPossession.driverFetching:
        return 'السائق يجلب';
      case OrderPossession.driverShipping:
        return 'السائق يوصل';
      case OrderPossession.driverReturning:
        return 'السائق يرجع للزبون';

      case OrderPossession.branch:
        return 'الفرع';
      case OrderPossession.customer:
        return 'العميل';
    }
  }
}

class Shipment {
  final String? customerlocation;
  final String? userphone;
  final String orderId;

  final String? username;
  final String? userId;
  final String? senderName;
  final String? profileImageUrl;
  final String? driverId;
  final String? driverName;
  final List<ShipmentLog> logs;
  final PackageAttributes packageAttributes;
  final double deliveryCost;
  final String collectionMethod;
  final String recipientName;
  final String phoneNumber;
  final String? secondaryPhoneNumber;
  final String city;
  final String addressDescription;
  final String paymentMethod;
  final double codAmount;
  final String serviceType;
  final String trackingNumber;
  final String contents;
  final double weight;
  final String notes;
  final int parcelCount;
  final String status;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final DateTime? deliveryDate;
  final DateTime? expectedDeliveryDate;
  final DateTime? returnOrderDate;
  final DateTime? postponementDate;
  final CashPossession cashPossession;
  final OrderPossession orderPossession;
  final Driver? driver;
  bool receivedMoneyFromCustomer;
  bool getMoneyFromUserPalance;
  bool? returnedAfterDelivery;
  List<String> images;
  String? get shelfId => shelf?.id;
  String? get shelfName => shelf?.name;
  final Map<String, int>? selectedItems;
  final bool? isShipmentWithItems;
  double? driverPrice;
  final Shelf? shelf;
  final bool reassignedToDriver;
  final bool isSentToFaotara;
  int? otp;
  final bool isAddressed;

  // New fields for Collection Logic
  final bool
      isDeliveryFeeOnRecipient; // المستلم سيدفع سعر التوصيل (true by default usually)
  final bool
      isCompanyDeliveryFeePaid; // واصل الشركة (true if paid to company, false otherwise)
  final bool isPayToRecipient; // الدفع للمستلم
  final double
      returnedOrderCollection; // اجور الطلب المرتجع (تحصيل السائق عند الإرجاع)

  Shipment({
    this.customerlocation,
    this.userphone,
    required this.orderId,
    this.username,
    this.userId,
    this.profileImageUrl,
    this.driverId,
    this.driverName,
    this.logs = const [],
    required this.packageAttributes,
    required this.deliveryCost,
    required this.collectionMethod,
    required this.recipientName,
    required this.phoneNumber,
    this.secondaryPhoneNumber,
    required this.city,
    required this.addressDescription,
    required this.paymentMethod,
    required this.codAmount,
    required this.serviceType,
    required this.trackingNumber,
    required this.contents,
    required this.weight,
    required this.notes,
    required this.parcelCount,
    required this.status,
    required this.createdAt,
    required this.lastUpdated,
    this.deliveryDate,
    this.expectedDeliveryDate,
    this.postponementDate,
    required this.cashPossession,
    required this.orderPossession,
    this.driver,
    this.returnOrderDate,
    this.receivedMoneyFromCustomer = false,
    this.getMoneyFromUserPalance = true,
    this.returnedAfterDelivery,
    this.images = const [],
    this.selectedItems,
    this.isShipmentWithItems = false,
    this.shelf,
    this.reassignedToDriver = false,
    this.otp,
    this.isSentToFaotara = false,
    this.isAddressed = false,
    this.senderName,
    this.isDeliveryFeeOnRecipient = true,
    this.isCompanyDeliveryFeePaid = false,
    this.isPayToRecipient = false,
    this.returnedOrderCollection = 0.0,
  });

  factory Shipment.fromMap(Map<String, dynamic> map) {
    return Shipment(
      shelf: map['shelf'] != null
          ? Shelf.fromMap(Map<String, dynamic>.from(map['shelf'] as Map))
          : null,
      returnOrderDate: map['returnOrderDate'] != null
          ? _parseDate(map['returnOrderDate'])
          : null,
      customerlocation: map['customerlocation'],
      userphone: map['userphone'] ?? '',
      orderId: map['orderId'] ?? '',
      username: map['username'] ?? '',
      userId: map['userId'],
      senderName: map['senderName'],
      profileImageUrl: map['profileImageUrl'],
      driverId: map['driverId'],
      driverName: map['driverName'],
      logs: (map['logs'] as List? ?? [])
          .map((log) =>
              ShipmentLog.fromMap(Map<String, dynamic>.from(log as Map)))
          .toList(),
      packageAttributes: PackageAttributes.fromMap(
          Map<String, dynamic>.from(map['packageAttributes'] as Map? ?? {})),
      deliveryCost: map['deliveryCost'] != null
          ? double.parse(map['deliveryCost'].toString())
          : 0.0,
      collectionMethod: map['collectionMethod'] ?? '',
      recipientName: map['recipientName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      secondaryPhoneNumber: map['secondaryPhoneNumber'],
      city: map['city'] ?? '',
      addressDescription: map['addressDescription'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      codAmount: map['codAmount'] != null
          ? double.parse(map['codAmount'].toString())
          : 0.0,
      serviceType: map['serviceType'] ?? '',
      trackingNumber: map['trackingNumber'] ?? '',
      contents: map['contents'] ?? '',
      weight:
          map['weight'] != null ? double.parse(map['weight'].toString()) : 0.0,
      notes: map['notes'] ?? '',
      parcelCount: map['parcelCount'] ?? 0,
      status: map['status'] ?? '',
      createdAt: _parseDate(map['createdAt']),
      lastUpdated: _parseDate(map['lastUpdated']),
      deliveryDate:
          map['deliveryDate'] != null ? _parseDate(map['deliveryDate']) : null,
      expectedDeliveryDate: map['expectedDeliveryDate'] != null
          ? _parseDate(map['expectedDeliveryDate'])
          : null,
      postponementDate: map['postponementDate'] != null
          ? _parseDate(map['postponementDate'])
          : null,
      cashPossession: CashPossession.values.firstWhere(
        (e) =>
            e.toString().split('.').last == (map['cashPossession'] ?? 'branch'),
        orElse: () => CashPossession.branch,
      ),
      driver: map['driverId'] == null
          ? null
          : Driver(
              userid: map['driverId'],
              username: map['driverName'],
            ),
      receivedMoneyFromCustomer: map['receivedMoneyFromCustomer'] ?? false,
      getMoneyFromUserPalance: map['getMoneyFromUserPalance'] ?? true,
      returnedAfterDelivery: map['returnedAfterDelivery'],
      images: map['images'] != null ? List<String>.from(map['images']) : [],
      selectedItems: map['selectedItems'] != null
          ? Map<String, int>.from(map['selectedItems'])
          : null,
      isShipmentWithItems: map['isShipmentWithItems'] ?? false,
      reassignedToDriver: map['reassignedToDriver'] ?? false,
      orderPossession:
          orderPossessionFallback(map['status'], map['orderPossession']),
      otp: map['otp'],
      isSentToFaotara: map['isSentToFaotara'] ?? false,
      isAddressed: map['isAddressed'] ?? false,
      isDeliveryFeeOnRecipient: map['isDeliveryFeeOnRecipient'] ?? true,
      isCompanyDeliveryFeePaid: map['isCompanyDeliveryFeePaid'] ?? false,
      isPayToRecipient: map['isPayToRecipient'] ?? false,
      returnedOrderCollection:
          (map['returnedOrderCollection'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shelf': shelf?.toMap(),
      'returnOrderDate': returnOrderDate?.toIso8601String(),
      'customerlocation': customerlocation,
      'userphone': userphone,
      'orderId': orderId,
      'username': username,
      'userId': userId,
      'senderName': senderName,
      'profileImageUrl': profileImageUrl,
      'driverId': driverId,
      'driverName': driverName,
      'logs': logs.map((log) => log.toMap()).toList(),
      'packageAttributes': packageAttributes.toMap(),
      'deliveryCost': deliveryCost,
      'collectionMethod': collectionMethod,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'secondaryPhoneNumber': secondaryPhoneNumber,
      'city': city,
      'addressDescription': addressDescription,
      'orderPossession': orderPossession.toString().split('.').last,
      'paymentMethod': paymentMethod,
      'codAmount': codAmount,
      'serviceType': serviceType,
      'trackingNumber': trackingNumber,
      'contents': contents,
      'weight': weight,
      'notes': notes,
      'parcelCount': parcelCount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'expectedDeliveryDate': expectedDeliveryDate?.toIso8601String(),
      'postponementDate': postponementDate?.toIso8601String(),
      'cashPossession': cashPossession.toString().split('.').last,
      'receivedMoneyFromCustomer': receivedMoneyFromCustomer,
      'getMoneyFromUserPalance': getMoneyFromUserPalance,
      "timestamp": FieldValue.serverTimestamp(),
      'returnedAfterDelivery': returnedAfterDelivery,
      'images': images,
      'selectedItems': selectedItems,
      'isShipmentWithItems': isShipmentWithItems,
      'otp': otp,
      'reassignedToDriver': reassignedToDriver,
      'isSentToFaotara': isSentToFaotara,
      'isAddressed': isAddressed,
      'isDeliveryFeeOnRecipient': isDeliveryFeeOnRecipient,
      'isCompanyDeliveryFeePaid': isCompanyDeliveryFeePaid,
      'isPayToRecipient': isPayToRecipient,
      'returnedOrderCollection': returnedOrderCollection,
    };
  }

  Shipment copyWith({
    String? shelfId,
    String? shelfName,
    Shelf? shelf,
    String? customerlocation,
    String? userphone,
    String? orderId,
    String? username,
    String? userId,
    String? senderName,
    String? profileImageUrl,
    String? driverId,
    String? driverName,
    List<ShipmentLog>? logs,
    PackageAttributes? packageAttributes,
    double? deliveryCost,
    String? collectionMethod,
    String? recipientName,
    String? phoneNumber,
    String? secondaryPhoneNumber,
    String? city,
    String? addressDescription,
    String? paymentMethod,
    double? codAmount,
    String? serviceType,
    String? trackingNumber,
    String? contents,
    double? weight,
    String? notes,
    int? parcelCount,
    String? status,
    DateTime? createdAt,
    DateTime? lastUpdated,
    DateTime? deliveryDate,
    DateTime? expectedDeliveryDate,
    DateTime? postponementDate,
    DateTime? returnOrderDate,
    CashPossession? cashPossession,
    bool? receivedMoneyFromCustomer,
    bool? getMoneyFromUserPalance,
    bool? returnedAfterDelivery,
    List<String>? images,
    Map<String, int>? selectedItems,
    bool? isShipmentWithItems,
    Driver? driver,
    bool? reassignedToDriver,
    OrderPossession? orderPossession,
    int? otp,
    bool? isSentToFaotara,
    bool? isAddressed,
    bool? isDeliveryFeeOnRecipient,
    bool? isCompanyDeliveryFeePaid,
    bool? isPayToRecipient,
  }) {
    return Shipment(
      shelf: shelf ?? this.shelf,
      returnOrderDate: returnOrderDate ?? this.returnOrderDate,
      customerlocation: customerlocation ?? this.customerlocation,
      userphone: userphone ?? this.userphone,
      orderId: orderId ?? this.orderId,
      username: username ?? this.username,
      userId: userId ?? this.userId,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      logs: logs ?? this.logs,
      packageAttributes: packageAttributes ?? this.packageAttributes,
      deliveryCost: deliveryCost ?? this.deliveryCost,
      senderName: senderName ?? this.senderName,
      collectionMethod: collectionMethod ?? this.collectionMethod,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      secondaryPhoneNumber: secondaryPhoneNumber ?? this.secondaryPhoneNumber,
      city: city ?? this.city,
      addressDescription: addressDescription ?? this.addressDescription,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      codAmount: codAmount ?? this.codAmount,
      serviceType: serviceType ?? this.serviceType,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      contents: contents ?? this.contents,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
      parcelCount: parcelCount ?? this.parcelCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      postponementDate: postponementDate ?? this.postponementDate,
      orderPossession: orderPossession ?? this.orderPossession,
      cashPossession: cashPossession ?? this.cashPossession,
      receivedMoneyFromCustomer:
          receivedMoneyFromCustomer ?? this.receivedMoneyFromCustomer,
      getMoneyFromUserPalance:
          getMoneyFromUserPalance ?? this.getMoneyFromUserPalance,
      returnedAfterDelivery:
          returnedAfterDelivery ?? this.returnedAfterDelivery,
      images: images ?? this.images,
      selectedItems: selectedItems ?? this.selectedItems,
      isShipmentWithItems: isShipmentWithItems ?? this.isShipmentWithItems,
      driver: driver ?? this.driver,
      reassignedToDriver: reassignedToDriver ?? this.reassignedToDriver,
      otp: otp ?? this.otp,
      isSentToFaotara: isSentToFaotara ?? this.isSentToFaotara,
      isAddressed: isAddressed ?? this.isAddressed,
      isDeliveryFeeOnRecipient:
          isDeliveryFeeOnRecipient ?? this.isDeliveryFeeOnRecipient,
      isCompanyDeliveryFeePaid:
          isCompanyDeliveryFeePaid ?? this.isCompanyDeliveryFeePaid,
      isPayToRecipient: isPayToRecipient ?? this.isPayToRecipient,
      returnedOrderCollection:
          returnedOrderCollection ?? this.returnedOrderCollection,
    );
  }

  double get driverCollection {
    double collection = 0.0;

    if (status == 'تم إرجاعها') {
      return returnedOrderCollection;
    }

    if (paymentMethod == 'مدفوعة مسبقا') {
      if (isDeliveryFeeOnRecipient) {
        if (!isCompanyDeliveryFeePaid) {
          collection = deliveryCost;
        }
      }
    } else if (paymentMethod == 'COD') {
      collection = codAmount;
    } else if (paymentMethod == 'تبديل' || paymentMethod == 'إحضار') {
      if (!isPayToRecipient) {
        // التحصيل من المستلم
        collection = codAmount;
      }
    }

    return collection;
  }

  double get payableToCustomer {
    double payable = 0.0;

    if (status == 'تم إرجاعها') {
      if (getMoneyFromUserPalance) {
        return -(deliveryCost - returnedOrderCollection);
      }
      return 0;
    }

    if (paymentMethod == 'مدفوعة مسبقا') {
      if (!isDeliveryFeeOnRecipient && !isCompanyDeliveryFeePaid) {
        payable = -deliveryCost;
      }
    } else if (paymentMethod == 'COD') {
      payable = codAmount - deliveryCost;
    } else if (paymentMethod == 'تبديل' || paymentMethod == 'إحضار') {
      if (isPayToRecipient) {
        payable = -codAmount - deliveryCost;
      } else {
        payable = codAmount - deliveryCost;
      }
    }

    return payable;
  }

  static List<Shipment> getShipmentsWithDriverPrice(
      List<Shipment> shipments, List<ShippingRoute> driverShippingRoute) {
    List<Shipment> shipmentsWithDriverPrice = [];
    for (var shipment in shipments) {
      print(shipment.city);
      List<ShippingRoute> shippingRoute = driverShippingRoute
          .where((element) => shipment.city.contains(element.to))
          .toList();

      if (shippingRoute.isNotEmpty) {
        shipment.driverPrice = shippingRoute.first.deliveryPrice;
      } else {
        shipment.driverPrice = 0;
      }

      shipmentsWithDriverPrice.add(shipment);
    }
    return shipmentsWithDriverPrice;
  }

  String get whatsappNumber {
    return phoneNumber.replaceFirst("07", "+9627");
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
