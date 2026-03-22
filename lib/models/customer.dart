enum CustomerType { passenger, restaurant, buyer, shop }

class AddressInfo {
  final String address;
  final double latitude;
  final double longitude;

  AddressInfo({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory AddressInfo.fromJson(Map<String, dynamic> json) {
    return AddressInfo(
      address: json['address'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };
}

class Customer {
  String userid;
  String username;
  String email;
  String password;
  String phoneNumber; // Keeping as non-nullable to match existing usage
  String address;
  String profileImage;
  String? city; // Keeping as nullable to match existing usage
  double? cashBalance;

  // New fields from User1
  String? promotionalName;
  CustomerType customerType;
  double latitude;
  double longitude;
  List<AddressInfo> savedAddresses;
  String status;
  double userRating;
  int ratingCount;
  double loyaltyPoints;
  DateTime createdAt;
  DateTime updatedAt;
  bool isIdVerified;
  bool isCommercialVerified;
  bool isFaceVerified;
  bool isPhoneVerified;
  String? nationalId;

  // Existing booleans
  bool? allowAdminModification;
  bool? allowOtherAdminsModification;
  bool? showPriceInApp;
  bool? showDriverInApp;
  bool? showAddressInApp;
  bool? showPhoneInApp;

  Customer({
    required this.userid,
    required this.username,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.city,
    required this.address,
    required this.profileImage,
    this.cashBalance = 0.0,

    // New fields with defaults to ensure backward compatibility
    this.promotionalName,
    this.customerType = CustomerType.shop,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.savedAddresses = const [],
    this.status = 'معلق',
    this.userRating = 0.0,
    this.ratingCount = 0,
    this.loyaltyPoints = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isIdVerified = false,
    this.isCommercialVerified = false,
    this.isFaceVerified = false,
    this.isPhoneVerified = false,
    this.nationalId,

    // Existing optional booleans
    this.allowAdminModification,
    this.allowOtherAdminsModification,
    this.showPriceInApp,
    this.showDriverInApp,
    this.showAddressInApp,
    this.showPhoneInApp,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Customer.fromJson(Map<String, dynamic> json) {
    var list = json['savedAddresses'] as List? ?? json['addresses'] as List?;
    List<AddressInfo> savedAddressesList = [];
    if (list != null) {
      savedAddressesList = list.map((i) => AddressInfo.fromJson(i)).toList();
    }

    return Customer(
      userid: json['userid'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      phoneNumber: json['phone number'] ??
          json['userphone'] ??
          json['phoneNumber'] ??
          '', // Default to empty string if null
      address: json['address'] ?? json['address1'] ?? '',
      city: json['city'] ?? '', // Can be null in DB, but User1 defaults to empty string
      profileImage: json['profileImage'] ?? '',
      cashBalance: (json['cashBalance'] ?? 0.0).toDouble(),

      // New fields extraction
      promotionalName: json['promotionalName'] ?? '',
      nationalId: json['nationalId'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      customerType: CustomerType.values.firstWhere(
        (e) => e.name == json['customerType'],
        orElse: () => CustomerType.shop,
      ),
      savedAddresses: savedAddressesList,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is String
              ? DateTime.parse(json['createdAt'])
              : json['createdAt'].toDate())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is String
              ? DateTime.parse(json['updatedAt'])
              : json['updatedAt'].toDate())
          : DateTime.now(),
      isIdVerified: json['isIdVerified'] ?? false,
      isCommercialVerified: json['isCommercialVerified'] ?? false,
      isFaceVerified: json['isFaceVerified'] ?? false,
      isPhoneVerified: json['isPhoneVerified'] ?? false,
      status: json['status'] != null && json['status'].toString().isNotEmpty
          ? json['status'].toString()
          : 'معلق',
      userRating: json['userRating']?.toDouble() ?? 4.8,
      ratingCount: json['ratingCount'] ?? 0,
      loyaltyPoints: json['loyaltyPoints']?.toDouble() ?? 0,

      // Existing fields
      allowAdminModification: json['allowAdminModification'] ?? false,
      allowOtherAdminsModification:
          json['allowOtherAdminsModification'] ?? false,
      showPriceInApp: json['showPriceInApp'] ?? false,
      showDriverInApp: json['showDriverInApp'] ?? false,
      showAddressInApp: json['showAddressInApp'] ?? false,
      showPhoneInApp: json['showPhoneInApp'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'userid': userid,
        'username': username,
        'email': email,
        'password': password,
        'phone number': phoneNumber,
        'address': address,
        'city': city,
        'profileImage': profileImage,
        'cashBalance': cashBalance,

        // New fields
        'promotionalName': promotionalName,
        'customerType': customerType.name,
        'latitude': latitude,
        'longitude': longitude,
        'savedAddresses': savedAddresses.map((e) => e.toJson()).toList(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'isIdVerified': isIdVerified,
        'isCommercialVerified': isCommercialVerified,
        'isFaceVerified': isFaceVerified,
        'isPhoneVerified': isPhoneVerified,
        'status': status,
        'userRating': userRating,
        'ratingCount': ratingCount,
        'loyaltyPoints': loyaltyPoints,
        'nationalId': nationalId,

        // Existing fields
        'allowAdminModification': allowAdminModification,
        'allowOtherAdminsModification': allowOtherAdminsModification,
        'showPriceInApp': showPriceInApp,
        'showDriverInApp': showDriverInApp,
        'showAddressInApp': showAddressInApp,
        'showPhoneInApp': showPhoneInApp,
      };

  Customer copyWith({
    String? userid,
    String? username,
    String? email,
    String? password,
    String? phoneNumber,
    String? address,
    String? city, // Nullable to match field
    String? profileImage,
    double? cashBalance,
    CustomerType? customerType,
    String? promotionalName,
    double? latitude,
    double? longitude,
    List<AddressInfo>? savedAddresses,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isIdVerified,
    bool? isCommercialVerified,
    bool? isFaceVerified,
    bool? isPhoneVerified,
    String? status,
    double? userRating,
    int? ratingCount,
    double? loyaltyPoints,
    String? nationalId,
    bool? allowAdminModification,
    bool? allowOtherAdminsModification,
    bool? showPriceInApp,
    bool? showDriverInApp,
    bool? showAddressInApp,
    bool? showPhoneInApp,
  }) {
    return Customer(
      userid: userid ?? this.userid,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      city: city ?? this.city,
      profileImage: profileImage ?? this.profileImage,
      cashBalance: cashBalance ?? this.cashBalance,
      customerType: customerType ?? this.customerType,
      promotionalName: promotionalName ?? this.promotionalName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isIdVerified: isIdVerified ?? this.isIdVerified,
      isCommercialVerified: isCommercialVerified ?? this.isCommercialVerified,
      isFaceVerified: isFaceVerified ?? this.isFaceVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      status: status ?? this.status,
      userRating: userRating ?? this.userRating,
      ratingCount: ratingCount ?? this.ratingCount,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      nationalId: nationalId ?? this.nationalId,
      allowAdminModification:
          allowAdminModification ?? this.allowAdminModification,
      allowOtherAdminsModification:
          allowOtherAdminsModification ?? this.allowOtherAdminsModification,
      showPriceInApp: showPriceInApp ?? this.showPriceInApp,
      showDriverInApp: showDriverInApp ?? this.showDriverInApp,
      showAddressInApp: showAddressInApp ?? this.showAddressInApp,
      showPhoneInApp: showPhoneInApp ?? this.showPhoneInApp,
    );
  }
}
