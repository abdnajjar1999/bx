class PackageType {
  final String id;
  final String name;
  final double length;
  final double width;
  final double height;
  final double weight;

  PackageType({
    required this.id,
    required this.name,
    required this.length,
    required this.width,
    required this.height,
    required this.weight,
  });

  factory PackageType.fromMap(Map<String, dynamic> map) {
    return PackageType(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      length: double.tryParse(map['length']?.toString() ?? '0') ?? 0.0,
      width: double.tryParse(map['width']?.toString() ?? '0') ?? 0.0,
      height: double.tryParse(map['height']?.toString() ?? '0') ?? 0.0,
      weight: double.tryParse(map['weight']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'length': length,
      'width': width,
      'height': height,
      'weight': weight,
    };
  }
}
