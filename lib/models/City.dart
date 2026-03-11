class City {
  final String name;
  final List<String> places;

  City({
    required this.name,
    required this.places,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'places': places,
    };
  }

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'] as String,
      places: List<String>.from(json['places'] as List),
    );
  }

} 