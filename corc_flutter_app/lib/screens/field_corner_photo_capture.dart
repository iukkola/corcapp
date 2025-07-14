import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import '../services/api_service.dart';

class FieldCornerPhotoCaptureScreen extends StatefulWidget {
  final int fieldId;
  final String fieldName;
  final List<List<double>> fieldCoordinates;

  const FieldCornerPhotoCaptureScreen({
    Key? key,
    required this.fieldId,
    required this.fieldName,
    required this.fieldCoordinates,
  }) : super(key: key);

  @override
  State<FieldCornerPhotoCaptureScreen> createState() => _FieldCornerPhotoCaptureScreenState();
}

class _FieldCornerPhotoCaptureScreenState extends State<FieldCornerPhotoCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  Position? _currentPosition;
  bool _isLoading = false;
  String? _statusMessage;
  Map<String, dynamic>? _analysisResult;
  
  // Corner capture state
  int _currentCornerIndex = 0;
  List<Map<String, dynamic>> _capturedCorners = [];
  List<Map<String, dynamic>> _targetCorners = [];
  
  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _calculateTargetCorners();
    _getCurrentLocation();
  }

  void _calculateTargetCorners() {
    if (widget.fieldCoordinates.length < 3) return;
    
    // Calculate field bounds
    double minLat = widget.fieldCoordinates.map((c) => c[0]).reduce(math.min);
    double maxLat = widget.fieldCoordinates.map((c) => c[0]).reduce(math.max);
    double minLon = widget.fieldCoordinates.map((c) => c[1]).reduce(math.min);
    double maxLon = widget.fieldCoordinates.map((c) => c[1]).reduce(math.max);
    
    // Define the four corners
    _targetCorners = [
      {
        'name': 'Koilliskulma (NE)',
        'coordinates': [maxLat, maxLon],
        'direction': 'northeast',
        'icon': Icons.north_east,
        'color': Colors.blue,
        'description': 'Mene kentän oikeaan yläkulmaan'
      },
      {
        'name': 'Kaakkokulma (SE)', 
        'coordinates': [minLat, maxLon],
        'direction': 'southeast',
        'icon': Icons.south_east,
        'color': Colors.orange,
        'description': 'Mene kentän oikeaan alakulmaan'
      },
      {
        'name': 'Lounaskulma (SW)',
        'coordinates': [minLat, minLon],
        'direction': 'southwest', 
        'icon': Icons.south_west,
        'color': Colors.red,
        'description': 'Mene kentän vasempaan alakulmaan'
      },
      {
        'name': 'Luodekulma (NW)',
        'coordinates': [maxLat, minLon],
        'direction': 'northwest',
        'icon': Icons.north_west,
        'color': Colors.green,
        'description': 'Mene kentän vasempaan yläkulmaan'
      }
    ];
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _initializeControllerFuture = _controller!.initialize();
      setState(() {});
    }
  }

  Future<void> _getCurrentLocation() async {
    var locationPermission = await Permission.location.request();
    var cameraPermission = await Permission.camera.request();
    
    if (locationPermission.isGranted && cameraPermission.isGranted) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _statusMessage = _getNavigationMessage();
        });
      } catch (e) {
        setState(() {
          _statusMessage = 'Virhe GPS-sijainnin haussa: $e';
        });
      }
    } else {
      setState(() {
        _statusMessage = 'Tarvitaan kamera- ja GPS-käyttöoikeudet';
      });
    }
  }

  String _getNavigationMessage() {
    if (_currentPosition == null || _currentCornerIndex >= _targetCorners.length) {
      return 'Haetaan GPS-sijaintia...';
    }
    
    var targetCorner = _targetCorners[_currentCornerIndex];
    var targetCoords = targetCorner['coordinates'] as List<double>;
    
    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetCoords[0],
      targetCoords[1],
    );
    
    if (distance <= 15) {
      return '✅ Olet kulmassa! Voit ottaa kuvan (${distance.round()}m)';
    } else if (distance <= 50) {
      return '🚶 Lähes perillä! ${distance.round()}m kulmaan';
    } else {
      return '🧭 ${targetCorner['description']} - ${distance.round()}m';
    }
  }

  bool _isAtTargetCorner() {
    if (_currentPosition == null || _currentCornerIndex >= _targetCorners.length) {
      return false;
    }
    
    var targetCorner = _targetCorners[_currentCornerIndex];
    var targetCoords = targetCorner['coordinates'] as List<double>;
    
    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetCoords[0],
      targetCoords[1],
    );
    
    return distance <= 15; // Within 15 meters
  }

  Future<void> _captureCornerPhoto() async {
    if (!_isAtTargetCorner()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mene lähemmäs kulmaa ennen kuvan ottamista')),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Otetaan kuva...';
      });

      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      
      setState(() {
        _statusMessage = 'Analysoidaan kuvaa...';
      });

      // Convert image to base64
      final bytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      // Get current GPS coordinates
      final currentGPS = _currentPosition;
      
      setState(() {
        _statusMessage = currentGPS != null 
          ? 'GPS: ${currentGPS.latitude.toStringAsFixed(6)}, ${currentGPS.longitude.toStringAsFixed(6)}'
          : 'GPS ei saatavilla - analysoidaan kuva...';
      });
      
      await Future.delayed(Duration(seconds: 1)); // Show GPS coordinates briefly

      // Send to backend for analysis
      final apiService = ApiService();
      final result = await apiService.analyzeFieldPhoto(widget.fieldId, base64Image);
      
      // Store corner data
      var cornerData = {
        'corner_index': _currentCornerIndex,
        'corner_name': _targetCorners[_currentCornerIndex]['name'],
        'gps_coordinates': [_currentPosition!.latitude, _currentPosition!.longitude],
        'timestamp': DateTime.now().toIso8601String(),
        'analysis_result': result,
        'image_path': image.path,
      };
      
      _capturedCorners.add(cornerData);
      
      setState(() {
        _analysisResult = result;
        _isLoading = false;
        _statusMessage = 'Kulma ${_currentCornerIndex + 1}/4 tallennettu!';
      });

      // Move to next corner after delay
      Future.delayed(Duration(seconds: 2), () {
        _moveToNextCorner();
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Virhe kuvan käsittelyssä: $e';
      });
    }
  }

  void _moveToNextCorner() {
    if (_currentCornerIndex < _targetCorners.length - 1) {
      setState(() {
        _currentCornerIndex++;
        _analysisResult = null;
        _statusMessage = _getNavigationMessage();
      });
    } else {
      // All corners captured
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🎉 Kaikki kulmat tallennettu!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Olet onnistuneesti kuvannut kaikki 4 kentän kulmaa.'),
            SizedBox(height: 16),
            Text('Tallennetut kulmat:'),
            ..._capturedCorners.map((corner) => ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text(corner['corner_name']),
              subtitle: Text('${corner['gps_coordinates'][0].toStringAsFixed(6)}, ${corner['gps_coordinates'][1].toStringAsFixed(6)}'),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Sulje'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportResearchData();
            },
            child: Text('Vie tutkimusdata'),
          ),
        ],
      ),
    );
  }

  void _exportResearchData() {
    // TODO: Implement research data export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tutkimusdatan vienti toteutetaan seuraavassa vaiheessa')),
    );
  }

  Widget _buildCornerProgress() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Kulma ${_currentCornerIndex + 1}/4',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: _currentCornerIndex / _targetCorners.length,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          SizedBox(height: 16),
          if (_currentCornerIndex < _targetCorners.length) ...[
            Card(
              color: _targetCorners[_currentCornerIndex]['color'].withOpacity(0.1),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _targetCorners[_currentCornerIndex]['icon'],
                      size: 48,
                      color: _targetCorners[_currentCornerIndex]['color'],
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _targetCorners[_currentCornerIndex]['name'],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            _targetCorners[_currentCornerIndex]['description'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisResults() {
    if (_analysisResult == null) return Container();

    final imageAnalysis = _analysisResult!['image_analysis'] ?? {};
    final vegetation = imageAnalysis['vegetation_analysis'] ?? {};
    final validation = imageAnalysis['validation'] ?? {};

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kulma-analyysi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            _buildResultRow(
              '🌱 Biomassa-arvio',
              '${imageAnalysis['biomass_estimate_kg_per_hectare'] ?? 0} kg/ha',
            ),
            _buildResultRow(
              '🌿 Kasvillisuus',
              '${vegetation['green_percentage'] ?? 0}%',
            ),
            _buildResultRow(
              '✅ Validointi',
              '${validation['overall_score'] ?? 0}/100',
              validation['overall_score'] > 70 ? Colors.green : Colors.orange,
            ),
            if (validation['photo_gps'] != null) ...[
              _buildResultRow(
                '📍 GPS-koordinaatit',
                '${validation['photo_gps'][0].toStringAsFixed(6)}, ${validation['photo_gps'][1].toStringAsFixed(6)}',
              ),
              _buildResultRow(
                '📏 Etäisyys kentältä',
                '${validation['gps_distance_meters'].toStringAsFixed(0)}m',
                validation['gps_valid'] ? Colors.green : Colors.red,
              ),
            ] else
              _buildResultRow(
                '📍 GPS-sijainti',
                'Ei saatavilla',
                Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kulmat: ${widget.fieldName}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildCornerProgress(),
          
          // Status message
          if (_statusMessage != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: _isAtTargetCorner() ? Colors.green.shade100 : Colors.orange.shade100,
              child: Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isAtTargetCorner() ? Colors.green.shade700 : Colors.orange.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          // Camera preview
          if (_controller != null)
            Expanded(
              flex: 2,
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return CameraPreview(_controller!);
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          
          // Analysis results
          if (_analysisResult != null)
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                child: _buildAnalysisResults(),
              ),
            ),
          
          // Controls
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                if (_currentPosition != null)
                  Text(
                    'GPS: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: Icon(Icons.refresh),
                      label: Text('Päivitä GPS'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading || !_isAtTargetCorner() ? null : _captureCornerPhoto,
                      icon: _isLoading 
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.camera_alt),
                      label: Text(_isLoading ? 'Analysoi...' : 'Ota kuva'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}