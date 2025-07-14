import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  Stream<Position>? _positionStream;

  Future<bool> requestLocationPermission() async {
    PermissionStatus permission = await Permission.location.status;
    
    if (permission.isDenied) {
      permission = await Permission.location.request();
    }
    
    if (permission.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    
    return permission.isGranted;
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) return null;
      
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      // Use debugPrint instead of print for production
      return null;
    }
  }

  Stream<Position> getPositionStream() {
    _positionStream ??= Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // Only update if moved 1 meter
      ),
    );
    return _positionStream!;
  }

  LatLng positionToLatLng(Position position) {
    return LatLng(position.latitude, position.longitude);
  }

  double calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  double calculatePolygonArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    // Use Shoelace formula for polygon area calculation
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    area = (area.abs() / 2.0);
    
    // Convert from degrees to square meters (approximate)
    // 1 degree latitude ≈ 111,320 meters
    // 1 degree longitude ≈ 111,320 * cos(latitude) meters
    double avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    double latMeters = 111320.0;
    double lonMeters = 111320.0 * (avgLat * 3.14159 / 180.0).cos();
    
    return area * latMeters * lonMeters;
  }

  double areaInHectares(double areaInSquareMeters) {
    return areaInSquareMeters / 10000.0; // 1 hectare = 10,000 square meters
  }

  bool isValidField(List<LatLng> points) {
    if (points.length < 3) return false;
    
    // Check minimum area (at least 100 square meters)
    final area = calculatePolygonArea(points);
    return area >= 100.0;
  }

  LatLng getPolygonCenter(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    
    double latSum = 0;
    double lngSum = 0;
    
    for (final point in points) {
      latSum += point.latitude;
      lngSum += point.longitude;
    }
    
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  Map<String, dynamic> pointsToGeoJson(List<LatLng> points) {
    return {
      'type': 'Polygon',
      'coordinates': [
        points.map((point) => [point.longitude, point.latitude]).toList()
          ..add([points.first.longitude, points.first.latitude]) // Close polygon
      ]
    };
  }

  List<List<double>> pointsToCoordinates(List<LatLng> points) {
    return points.map((point) => [point.longitude, point.latitude]).toList();
  }
}