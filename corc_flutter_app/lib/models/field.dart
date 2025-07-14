class Field {
  final int id;
  final String name;
  final List<List<double>> coordinates;
  final double? areaHectares;
  final DateTime createdAt;
  
  // Helper getters for center coordinates
  double get latitude {
    if (coordinates.isEmpty) return 0.0;
    double totalLat = 0.0;
    for (var coord in coordinates) {
      if (coord.length >= 2) totalLat += coord[1];
    }
    return totalLat / coordinates.length;
  }
  
  double get longitude {
    if (coordinates.isEmpty) return 0.0;
    double totalLon = 0.0;
    for (var coord in coordinates) {
      if (coord.length >= 2) totalLon += coord[0];
    }
    return totalLon / coordinates.length;
  }

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
          .map((coord) => List<double>.from(coord.map((c) => c.toDouble())))
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