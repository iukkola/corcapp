class NDVIData {
  final int id;
  final int fieldId;
  final DateTime date;
  final double ndviValue;
  final double? biomassEstimate;
  final String dataSource;

  NDVIData({
    required this.id,
    required this.fieldId,
    required this.date,
    required this.ndviValue,
    this.biomassEstimate,
    required this.dataSource,
  });

  factory NDVIData.fromJson(Map<String, dynamic> json) {
    return NDVIData(
      id: json['id'],
      fieldId: json['field_id'],
      date: DateTime.parse(json['date']),
      ndviValue: json['ndvi_value'].toDouble(),
      biomassEstimate: json['biomass_estimate']?.toDouble(),
      dataSource: json['data_source'],
    );
  }

  // Helper method to get NDVI health status
  String get healthStatus {
    if (ndviValue >= 0.6) return 'Terve kasvillisuus';
    if (ndviValue >= 0.3) return 'Kohtuullinen kasvu';
    if (ndviValue >= 0.1) return 'Vähäinen kasvu';
    if (ndviValue >= 0.0) return 'Paljas maa';
    return 'Vesi/pilvi';
  }

  // Helper method to get color for NDVI value
  int get healthColor {
    if (ndviValue >= 0.6) return 0xFF4CAF50; // Green
    if (ndviValue >= 0.3) return 0xFFFF9800; // Orange
    if (ndviValue >= 0.1) return 0xFFFFC107; // Yellow
    return 0xFFF44336; // Red
  }
}