class Vehicle {
  final String id;
  final String brand;
  final String model;
  final String size;
  final String plateNumber;
  final String? driverId;
  final String? driverName;
  final String vehicleType;
  final String fuelType;
  final DateTime? insuranceEndDate;
  final DateTime? licenseEndDate;
  final DateTime createdAt;
  final String status;

  Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.size,
    required this.plateNumber,
    this.driverId,
    this.driverName,
    required this.vehicleType,
    required this.fuelType,
    this.insuranceEndDate,
    this.licenseEndDate,
    required this.createdAt,
    required this.status,
  });

  // Create a Vehicle instance from a Firestore document
  factory Vehicle.fromFirestore(Map<String, dynamic> data, String id) {
    return Vehicle(
      id: id,
      brand: data['brand'] ?? '',
      model: data['model'] ?? '',
      size: data['size']?.toString() ?? '1',
      plateNumber: data['plateNumber'] ?? '',
      driverId: data['driverId'],
      driverName: data['driverName'],
      vehicleType: data['vehicleType'] ?? '',
      fuelType: data['fuelType'] ?? '',
      insuranceEndDate: data['insuranceEndDate'] != null
          ? DateTime.parse(data['insuranceEndDate'])
          : null,
      licenseEndDate: data['licenseEndDate'] != null
          ? DateTime.parse(data['licenseEndDate'])
          : null,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'active',
    );
  }

  // Convert Vehicle instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'size': size,
      'plateNumber': plateNumber,
      'driverId': driverId,
      'driverName': driverName,
      'vehicleType': vehicleType,
      'fuelType': fuelType,
      'insuranceEndDate': insuranceEndDate?.toIso8601String(),
      'licenseEndDate': licenseEndDate?.toIso8601String(),
      'createdAt': createdAt,
      'status': status,
      // Add searchable fields for better querying
      'searchFields': _createSearchFields(),
    };
  }

  // Create a copy of Vehicle with modified fields
  Vehicle copyWith({
    String? brand,
    String? model,
    String? size,
    String? plateNumber,
    String? driverId,
    String? driverName,
    String? vehicleType,
    String? fuelType,
    DateTime? insuranceEndDate,
    DateTime? licenseEndDate,
    String? status,
  }) {
    return Vehicle(
      id: id,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      size: size ?? this.size,
      plateNumber: plateNumber ?? this.plateNumber,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      vehicleType: vehicleType ?? this.vehicleType,
      fuelType: fuelType ?? this.fuelType,
      insuranceEndDate: insuranceEndDate ?? this.insuranceEndDate,
      licenseEndDate: licenseEndDate ?? this.licenseEndDate,
      createdAt: createdAt,
      status: status ?? this.status,
    );
  }

  // Helper method to create searchable fields
  List<String> _createSearchFields() {
    final searchFields = <String>{};

    void addNonEmptyField(String field) {
      if (field.isNotEmpty) {
        searchFields.add(field.toLowerCase());
        // Add individual words for better search
        searchFields.addAll(
            field.toLowerCase().split(' ').where((word) => word.isNotEmpty)
        );
      }
    }

    addNonEmptyField(brand);
    addNonEmptyField(model);
    addNonEmptyField(plateNumber);
    addNonEmptyField(driverName ?? '');
    addNonEmptyField(vehicleType);
    addNonEmptyField(fuelType);

    return searchFields.toList();
  }

  // Helper method to check if insurance is expired
  bool get isInsuranceExpired {
    if (insuranceEndDate == null) return true;
    return insuranceEndDate!.isBefore(DateTime.now());
  }

  // Helper method to check if license is expired
  bool get isLicenseExpired {
    if (licenseEndDate == null) return true;
    return licenseEndDate!.isBefore(DateTime.now());
  }

  // Helper method to get days remaining until insurance expiry
  int? get daysUntilInsuranceExpiry {
    if (insuranceEndDate == null) return null;
    return insuranceEndDate!.difference(DateTime.now()).inDays;
  }

  // Helper method to get days remaining until license expiry
  int? get daysUntilLicenseExpiry {
    if (licenseEndDate == null) return null;
    return licenseEndDate!.difference(DateTime.now()).inDays;
  }

  // Override toString for debugging
  @override
  String toString() {
    return 'Vehicle{id: $id, brand: $brand, model: $model, plateNumber: $plateNumber, '
        'driverName: $driverName, status: $status}';
  }

  // Override equality operator
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vehicle && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Enum for vehicle status
enum VehicleStatus {
  active,
  maintenance,
  deleted;

  String toFirestore() => name;

  static VehicleStatus fromFirestore(String status) {
    return VehicleStatus.values.firstWhere(
          (e) => e.name == status,
      orElse: () => VehicleStatus.active,
    );
  }
}