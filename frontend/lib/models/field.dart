class Field {
  final int id;
  final String name;
  final List<List<double>> coordinates;
  final double? areaHectares;
  final DateTime createdAt;

  Field({
    required this.id,
    required this.name,
    required this.coordinates,
    this.areaHectares,
    required this.createdAt,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['id'],
      name: json['name'],
      coordinates: (json['coordinates'] as List)
          .map((coord) => (coord as List).map((c) => c.toDouble()).toList())
          .toList(),
      areaHectares: json['area_hectares']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'coordinates': coordinates,
      'area_hectares': areaHectares,
      'created_at': createdAt.toIso8601String(),
    };
  }
}