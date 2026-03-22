import 'package:cloud_firestore/cloud_firestore.dart';

class UserInfo {
  final List<ActivityInfo>? activitiesList;
  final String activityNumber;
  final CountryInfo? country;
  final String username;
  final String name;
  final String invoiceTypeNumber;
  final String role;
  final String phoneNumber;
  final String postalCode;
  final String taxNumber;

  final bool deviceInUse;

  UserInfo({
    this.activitiesList,
    this.activityNumber = '-',
    this.country,
    this.username = '-',
    this.name = '-',
    this.invoiceTypeNumber = '0',
    this.role = '',
    this.phoneNumber = '-',
    this.postalCode = '-',
    this.taxNumber = '-',
    this.deviceInUse = false,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json, String language) {
    return UserInfo(
      activitiesList: json['activitiesList'] != null
          ? (json['activitiesList'] as List)
              .map((activity) => ActivityInfo.fromJson(activity))
              .toList()
          : null,
      activityNumber: json['activitiesList']?.isNotEmpty
          ? json['activitiesList'][0]?.activity ?? '-'
          : '-',
      country: json['countryDTO'] != null
          ? CountryInfo.fromJson(json['countryDTO'], language)
          : null,
      username: json['userName'] ?? '-',
      name: json['name'] ?? '-',
      invoiceTypeNumber: json['activitiesList']?.isNotEmpty
          ? json['activitiesList'][0]?.invoiceType?.toString() ?? '0'
          : '0',
      role: json['role'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '-',
      postalCode: json['postalCode'] ?? '-',
      taxNumber: json['taxNumber'] ?? '-',
      deviceInUse: json['deviceInUse'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activitiesList': activitiesList?.map((a) => a.toJson()).toList(),
      'activityNumber': activityNumber,
      'country': country?.toJson(),
      'username': username,
      'name': name,
      'invoiceTypeNumber': invoiceTypeNumber,
      'role': role,
      'phoneNumber': phoneNumber,
      'postalCode': postalCode,
      'taxNumber': taxNumber,
      'deviceInUse': deviceInUse,
    };
  }
}

class ActivityInfo {
  final String activity;
  final String? invoiceType;

  ActivityInfo({required this.activity, this.invoiceType});

  factory ActivityInfo.fromJson(Map<String, dynamic> json) {
    return ActivityInfo(
      activity: json['activity'] ?? '',
      invoiceType: json['invoiceType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'activity': activity, 'invoiceType': invoiceType};
  }
}

class CountryInfo {
  final String code;
  final String name;

  CountryInfo({required this.code, required this.name});

  factory CountryInfo.fromJson(Map<String, dynamic> json, String language) {
    return CountryInfo(
      code: json['countryCode'] ?? '',
      name: language == 'en'
          ? json['countryNameEn'] ?? ''
          : json['countryNameAr'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'code': code, 'name': name};
  }
}

class DeviceInfo {
  final String id;
  final String clientId;
  final String secretKey;
  final String name;
  final bool enabled;
  final String activityNumber;

  DeviceInfo({
    required this.id,
    required this.clientId,
    required this.secretKey,
    required this.name,
    required this.enabled,
    required this.activityNumber,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      id: json['id'] ?? '',
      clientId: json['clientId'] ?? '',
      secretKey: json['secretKey'] ?? '',
      name: json['name'] ?? '',
      enabled: json['enabled'] ?? false,
      activityNumber: json['activityNumber'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'secretKey': secretKey,
      'name': name,
      'enabled': enabled,
      'activityNumber': activityNumber,
    };
  }
}

class SubAdminInfo {
  final String id;
  final String username;
  final String password;
  final String notes;
  final bool enabled;
  final ActivityInfo? activityNumber;

  SubAdminInfo({
    required this.id,
    required this.username,
    this.password = '',
    this.notes = '',
    this.enabled = true,
    this.activityNumber,
  });

  factory SubAdminInfo.fromJson(Map<String, dynamic> json) {
    return SubAdminInfo(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      notes: json['notes'] ?? '',
      enabled: json['enabled'] ?? true,
      activityNumber: json['activityDTO'] != null
          ? ActivityInfo.fromJson(json['activityDTO'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'notes': notes,
      'enabled': enabled,
      'activityDTO': activityNumber?.toJson(),
    };
  }
}

class UserModel {
  final String name;
  final String email;
  final String phone;
  final bool isActive;
  final DateTime? activateDate;
  final String username;
  final String taxNumber;
  final String password;
  final List<String> buyerNames;
  final List<String> productDescriptions;
  String? uid;

  UserModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.isActive,
    required this.username,
    required this.taxNumber,
    required this.password,
    this.activateDate,
    this.uid,
    this.buyerNames = const [],
    this.productDescriptions = const [],
  });

  // Factory method to create a UserModel from a Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      isActive: data['isActive'] ?? false,
      username: data['username'] ?? '',
      taxNumber: data['taxNumber'] ?? '',
      password: data['password'] ?? '',
      activateDate: data['activateDate'] != null
          ? (data['activateDate'] as Timestamp).toDate()
          : null,
      uid: doc.id,
      buyerNames: data['buyerNames'] != null
          ? List<String>.from(data['buyerNames'])
          : [],
      productDescriptions: data['productDescriptions'] != null
          ? List<String>.from(data['productDescriptions'])
          : [],
    );
  }

  // Convert the UserModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'isActive': isActive,
      'username': username,
      'taxNumber': taxNumber,
      'activateDate': activateDate,
      'password': password,
      'buyerNames': buyerNames,
      'productDescriptions': productDescriptions,
    };
  }

  // Create a copy of the UserModel with modified fields
  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    bool? isActive,
    DateTime? activateDate,
    String? username,
    String? taxNumber,
    String? password,
    String? uid,
    List<String>? buyerNames,
    List<String>? productDescriptions,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      username: username ?? this.username,
      taxNumber: taxNumber ?? this.taxNumber,
      activateDate: activateDate ?? this.activateDate,
      uid: uid ?? this.uid,
      password: password ?? this.password,
      buyerNames: buyerNames ?? this.buyerNames,
      productDescriptions: productDescriptions ?? this.productDescriptions,
    );
  }
}
