class Driver {
  String? address;
  String? email;
  String? password; // Added password field
  String? location;
  String? phone;
  String? profileImage;
  String? userid;
  String? username;
  double? cashBalance;
  String? detailedAddress;
  String? branch;
  String? category;
  String? company;
  String? driverId;
  String? jobRole;
  String? status;

  double? driverShare;

  // Permissions and settings
  bool allowDeliveryParcel;
  bool allowDelayedDelivery;
  bool allowReturns;
  bool deliverToWarehouse;
  bool hideDriverInfo;
  bool hideRecipientInfo;
  bool requireSignature;
  bool allowDriverRefuse;
  bool hideBarcode;
  List<String> permissions;
  List<String> cities;
  Driver({
    this.address,
    this.email,
    this.password, // Added to constructor
    this.location,
    this.phone,
    this.profileImage,
    this.userid,
    this.username,
    this.cashBalance,
    this.detailedAddress,
    this.branch,
    this.category,
    this.company,
    this.driverId,
    this.jobRole,
    this.driverShare,
    this.allowDeliveryParcel = false,
    this.allowDelayedDelivery = false,
    this.allowReturns = false,
    this.deliverToWarehouse = false,
    this.hideDriverInfo = false,
    this.hideRecipientInfo = false,
    this.requireSignature = false,
    this.allowDriverRefuse = false,
    this.hideBarcode = false,
    this.permissions = const [],
    this.cities = const [],
    this.status
  });

  factory Driver.fromJson(Map<String, dynamic> map) {
    return Driver(
      address: map['address'],
      email: map['email'],
      password: map['password'], // Added to fromJson
      location: map['location'] ?? '',
      phone: map['phone number'],
      profileImage: map['profileImage'],
      userid: map['userid'],
      username: map['username'],
      cashBalance: map['cashBalance']?.toDouble() ?? 0.0,
      detailedAddress: map['detailedAddress'],
      branch: map['branch'],
      category: map['category'],
      company: map['company'],
      driverId: map['driverId'],
      jobRole: map['jobRole'],
      driverShare: map['driverShare']?.toDouble() ?? 0.0,
      allowDeliveryParcel: map['allowDeliveryParcel'] ?? false,
      allowDelayedDelivery: map['allowDelayedDelivery'] ?? false,
      allowReturns: map['allowReturns'] ?? false,
      deliverToWarehouse: map['deliverToWarehouse'] ?? false,
      hideDriverInfo: map['hideDriverInfo'] ?? false,
      hideRecipientInfo: map['hideRecipientInfo'] ?? false,
      requireSignature: map['requireSignature'] ?? false,
      allowDriverRefuse: map['allowDriverRefuse'] ?? false,
      hideBarcode: map['hideBarcode'] ?? false,
      permissions: List<String>.from(map['permissions'] ?? []),
      cities: List<String>.from(map['cities'] ?? []),
      status: map['status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'email': email,
      'password': password, // Added to toMap
      'location': location,
      'phone number': phone,
      'profileImage': profileImage,
      'userid': userid,
      'username': username,
      'cashBalance': cashBalance,
      'detailedAddress': detailedAddress,
      'branch': branch,
      'category': category,
      'company': company,
      'driverId': driverId,
      'jobRole': jobRole,
      'driverShare': driverShare,
      'allowDeliveryParcel': allowDeliveryParcel,
      'allowDelayedDelivery': allowDelayedDelivery,
      'allowReturns': allowReturns,
      'deliverToWarehouse': deliverToWarehouse,
      'hideDriverInfo': hideDriverInfo,
      'hideRecipientInfo': hideRecipientInfo,
      'requireSignature': requireSignature,
      'allowDriverRefuse': allowDriverRefuse,
      'hideBarcode': hideBarcode,
      'permissions': permissions,
      'cities': cities,
    };
  }

  Driver copyWith({
    String? address,
    String? email,
    String? password, // Added to copyWith
    String? location,
    String? phone,
    String? profileImage,
    String? userid,
    String? username,
    double? cashBalance,
    String? detailedAddress,
    String? branch,
    String? category,
    String? company,
    String? driverId,
    String? jobRole,
    double? driverShare,
    bool? allowDeliveryParcel,
    bool? allowDelayedDelivery,
    bool? allowReturns,
    bool? deliverToWarehouse,
    bool? hideDriverInfo,
    bool? hideRecipientInfo,
    bool? requireSignature,
    bool? allowDriverRefuse,
    bool? hideBarcode,
    List<String>? permissions,
    List<String>? cities,
  }) {
    return Driver(
      address: address ?? this.address,
      email: email ?? this.email,
      password: password ?? this.password, // Added to return statement
      location: location ?? this.location,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      userid: userid ?? this.userid,
      username: username ?? this.username,
      cashBalance: cashBalance ?? this.cashBalance,
      detailedAddress: detailedAddress ?? this.detailedAddress,
      branch: branch ?? this.branch,
      category: category ?? this.category,
      company: company ?? this.company,
      driverId: driverId ?? this.driverId,
      jobRole: jobRole ?? this.jobRole,
      driverShare: driverShare ?? this.driverShare,
      allowDeliveryParcel: allowDeliveryParcel ?? this.allowDeliveryParcel,
      allowDelayedDelivery: allowDelayedDelivery ?? this.allowDelayedDelivery,
      allowReturns: allowReturns ?? this.allowReturns,
      deliverToWarehouse: deliverToWarehouse ?? this.deliverToWarehouse,
      hideDriverInfo: hideDriverInfo ?? this.hideDriverInfo,
      hideRecipientInfo: hideRecipientInfo ?? this.hideRecipientInfo,
      requireSignature: requireSignature ?? this.requireSignature,
      allowDriverRefuse: allowDriverRefuse ?? this.allowDriverRefuse,
      hideBarcode: hideBarcode ?? this.hideBarcode,
      permissions: permissions ?? this.permissions,
      cities: cities ?? this.cities,
    );
  }
}
