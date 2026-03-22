
class Shelf {
  String? id;

  String name;
  String location;
  int? capacity;
  String? description;
  List<String>? shipmentIds; // IDs of shipments on this shelf

  Shelf({
    this.id,
    required this.name,
    required this.location,
    this.capacity,
    this.description,
    this.shipmentIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'location': location,
      'capacity': capacity,
      'description': description ?? '',
      'shipmentIds': shipmentIds ?? [],
    };
  }

  factory Shelf.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Shelf(
      id: docId ?? map['id'],
      name: map['name'] ?? '',
      location: map['location'] ?? '',
      capacity: map['capacity'],
      description: map['description'],
      shipmentIds: List<String>.from(map['shipmentIds'] ?? []),
    );
  }
}
