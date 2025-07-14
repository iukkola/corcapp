import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SimpleFieldMappingScreen extends StatefulWidget {
  @override
  _SimpleFieldMappingScreenState createState() => _SimpleFieldMappingScreenState();
}

class _SimpleFieldMappingScreenState extends State<SimpleFieldMappingScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _fieldNameController = TextEditingController();
  
  List<LatLng> _fieldBoundary = [];
  LatLng _mapCenter = const LatLng(16.5388, -24.0132); // Cape Verde center
  bool _isDrawing = false;

  void _startDrawing() {
    setState(() {
      _isDrawing = true;
      _fieldBoundary.clear();
    });
  }

  void _stopDrawing() {
    setState(() {
      _isDrawing = false;
    });
  }

  void _clearField() {
    setState(() {
      _fieldBoundary.clear();
      _isDrawing = false;
    });
  }

  void _addPoint(LatLng point) {
    if (!_isDrawing) return;
    
    setState(() {
      _fieldBoundary.add(point);
    });
  }

  double _calculateArea(List<LatLng> points) {
    if (points.length < 3) return 0.0;
    
    // Shoelace formula for polygon area
    double area = 0.0;
    for (int i = 0; i < points.length; i++) {
      int j = (i + 1) % points.length;
      area += points[i].latitude * points[j].longitude;
      area -= points[j].latitude * points[i].longitude;
    }
    area = (area.abs() / 2.0);
    
    // Approximate conversion to square meters for Cape Verde region
    double avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    double latMeters = 111320.0;
    double lonMeters = 111320.0 * math.cos(avgLat * 3.14159 / 180.0);
    
    return area * latMeters * lonMeters;
  }

  double _areaInHectares(double areaInSquareMeters) {
    return areaInSquareMeters / 10000.0;
  }

  Future<void> _saveField() async {
    if (_fieldBoundary.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Field must have at least 3 points')),
      );
      return;
    }

    if (_fieldNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a field name')),
      );
      return;
    }

    final area = _calculateArea(_fieldBoundary);
    final hectares = _areaInHectares(area);

    if (area < 100.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Field is too small (minimum 100 m²)')),
      );
      return;
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final coordinates = _fieldBoundary.map((point) => [point.longitude, point.latitude]).toList();
      
      final fieldData = {
        'name': _fieldNameController.text.trim(),
        'coordinates': coordinates,
        'area_hectares': hectares,
      };

      final response = await authService.apiService.createNewField(fieldData);
      
      if (response != null) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Field "${_fieldNameController.text}" saved successfully!')),
        );
      } else {
        throw Exception('Failed to save field');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving field: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final area = _fieldBoundary.length >= 3 ? _calculateArea(_fieldBoundary) : 0.0;
    final hectares = _areaInHectares(area);

    return Scaffold(
      appBar: AppBar(
        title: Text('Map Your Field'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (_fieldBoundary.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearField,
              tooltip: 'Clear field',
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _mapCenter,
              zoom: 15.0,
              onTap: (tapPosition, point) => _addPoint(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.corc.app',
              ),
              if (_fieldBoundary.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _fieldBoundary,
                      color: Colors.green.withOpacity(0.3),
                      borderColor: Colors.green,
                      borderStrokeWidth: 3.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: _fieldBoundary.asMap().entries.map((entry) {
                  final index = entry.key;
                  final point = entry.value;
                  return Marker(
                    point: point,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      width: 24,
                      height: 24,
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList().cast<Marker>(),
              ),
            ],
          ),
          
          // Info panel
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isDrawing ? 'Drawing Field Boundary' : 'Field Mapping',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isDrawing ? Colors.green : Colors.green.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Points: ${_fieldBoundary.length}'),
                        if (_fieldBoundary.length >= 3)
                          Text('Area: ${hectares.toStringAsFixed(3)} ha'),
                      ],
                    ),
                    if (_isDrawing) ...[
                      SizedBox(height: 8),
                      Text(
                        'Tap on the map to add boundary points.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Control buttons
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_fieldBoundary.length >= 3) ...[
                      TextField(
                        controller: _fieldNameController,
                        decoration: InputDecoration(
                          labelText: 'Field Name',
                          hintText: 'Enter field name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isDrawing ? _stopDrawing : _startDrawing,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isDrawing ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_isDrawing ? Icons.stop : Icons.edit),
                                SizedBox(width: 8),
                                Text(_isDrawing ? 'Stop Drawing' : 'Start Drawing'),
                              ],
                            ),
                          ),
                        ),
                        if (_fieldBoundary.length >= 3) ...[
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _saveField,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save),
                                  SizedBox(width: 8),
                                  Text('Save Field'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fieldNameController.dispose();
    super.dispose();
  }
}