import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';

class FieldMappingScreen extends StatefulWidget {
  @override
  _FieldMappingScreenState createState() => _FieldMappingScreenState();
}

class _FieldMappingScreenState extends State<FieldMappingScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService.instance;
  final TextEditingController _fieldNameController = TextEditingController();
  
  List<LatLng> _fieldBoundary = [];
  LatLng? _currentLocation;
  bool _isRecording = false;
  bool _isLoading = true;
  String? _error;
  
  Stream<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      final hasPermission = await _locationService.requestLocationPermission();
      if (!hasPermission) {
        setState(() {
          _error = 'Location permission denied';
          _isLoading = false;
        });
        return;
      }

      final serviceEnabled = await _locationService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Location services disabled';
          _isLoading = false;
        });
        return;
      }

      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final latLng = _locationService.positionToLatLng(position);
        setState(() {
          _currentLocation = latLng;
          _isLoading = false;
        });
        
        _mapController.move(latLng, 15.0);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to get location: $e';
        _isLoading = false;
      });
    }
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _fieldBoundary.clear();
    });
    
    _positionStream = _locationService.getPositionStream();
    _positionStream!.listen((position) {
      if (_isRecording) {
        final newPoint = _locationService.positionToLatLng(position);
        
        // Only add point if it's far enough from the last point (3 meters)
        if (_fieldBoundary.isEmpty || 
            _locationService.calculateDistance(_fieldBoundary.last, newPoint) > 3.0) {
          setState(() {
            _fieldBoundary.add(newPoint);
            _currentLocation = newPoint;
          });
        }
      }
    });
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
  }

  void _clearField() {
    setState(() {
      _fieldBoundary.clear();
      _isRecording = false;
    });
  }

  void _addPointManually(LatLng point) {
    if (!_isRecording) return;
    
    setState(() {
      _fieldBoundary.add(point);
    });
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

    final area = _locationService.calculatePolygonArea(_fieldBoundary);
    final hectares = _locationService.areaInHectares(area);

    if (!_locationService.isValidField(_fieldBoundary)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Field is too small (minimum 100 m²)')),
      );
      return;
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final coordinates = _locationService.pointsToCoordinates(_fieldBoundary);
      
      final fieldData = {
        'name': _fieldNameController.text.trim(),
        'coordinates': coordinates,
        'area_hectares': hectares,
      };

      final response = await authService.apiService.createNewField(fieldData);
      
      if (response != null) {
        Navigator.pop(context, true); // Return true to indicate field was created
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Field Mapping'),
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Field Mapping'),
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(_error!, style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeLocation,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final area = _fieldBoundary.length >= 3 
        ? _locationService.calculatePolygonArea(_fieldBoundary) 
        : 0.0;
    final hectares = _locationService.areaInHectares(area);

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
              center: _currentLocation ?? const LatLng(16.5388, -24.0132), // Cape Verde center
              zoom: 15.0,
              onTap: (tapPosition, point) => _addPointManually(point),
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
                markers: [
                  // Current location marker
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      builder: (context) => Container(
                        decoration: BoxDecoration(
                          color: _isRecording ? Colors.red : Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        width: 16,
                        height: 16,
                      ),
                    ),
                  // Field boundary markers
                  ..._fieldBoundary.asMap().entries.map((entry) {
                    final index = entry.key;
                    final point = entry.value;
                    return Marker(
                      point: point,
                      builder: (context) => Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        width: 12,
                        height: 12,
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
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
                      _isRecording ? 'Recording Field Boundary' : 'Field Mapping',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _isRecording ? Colors.red : Colors.green.shade700,
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
                    if (_isRecording) ...[
                      SizedBox(height: 8),
                      Text(
                        'Walk around your field boundary. Points are added automatically.',
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
                            onPressed: _isRecording ? _stopRecording : _startRecording,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRecording ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_isRecording ? Icons.stop : Icons.play_arrow),
                                SizedBox(width: 8),
                                Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
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