import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'dart:io';
import '../services/api_service.dart';

class FieldPhotoCaptureScreen extends StatefulWidget {
  final int fieldId;
  final String fieldName;
  final List<List<double>> fieldCoordinates;

  const FieldPhotoCaptureScreen({
    Key? key,
    required this.fieldId,
    required this.fieldName,
    required this.fieldCoordinates,
  }) : super(key: key);

  @override
  State<FieldPhotoCaptureScreen> createState() => _FieldPhotoCaptureScreenState();
}

class _FieldPhotoCaptureScreenState extends State<FieldPhotoCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  Position? _currentPosition;
  bool _isLoading = false;
  String? _statusMessage;
  Map<String, dynamic>? _analysisResult;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getCurrentLocation();
  }

  Future<void> _initializeCamera() async {
    // Get cameras
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
    // Request permissions
    var locationPermission = await Permission.location.request();
    var cameraPermission = await Permission.camera.request();
    
    if (locationPermission.isGranted && cameraPermission.isGranted) {
      try {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _statusMessage = _getLocationValidationMessage();
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

  String _getLocationValidationMessage() {
    if (_currentPosition == null) return 'Haetaan GPS-sijaintia...';
    
    // Calculate distance to field
    double minDistance = double.infinity;
    for (var coord in widget.fieldCoordinates) {
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        coord[0], // lat
        coord[1], // lon
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    
    if (minDistance <= 100) {
      return '✅ Olet pellon lähistöllä (${minDistance.round()}m)';
    } else {
      return '⚠️ Liian kaukana pellosta (${minDistance.round()}m). Mene lähemmäs.';
    }
  }

  bool _isLocationValid() {
    if (_currentPosition == null) return false;
    
    double minDistance = double.infinity;
    for (var coord in widget.fieldCoordinates) {
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        coord[0],
        coord[1],
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }
    
    return minDistance <= 100; // Within 100 meters
  }

  Future<void> _takePicture() async {
    if (!_isLocationValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mene lähemmäs peltoa ennen kuvan ottamista')),
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

      // Send to backend for analysis
      final apiService = ApiService();
      final result = await apiService.analyzeFieldPhoto(widget.fieldId, base64Image);
      
      setState(() {
        _analysisResult = result;
        _isLoading = false;
        _statusMessage = 'Analyysi valmis!';
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Virhe kuvan käsittelyssä: $e';
      });
    }
  }

  Widget _buildAnalysisResults() {
    if (_analysisResult == null) return Container();

    final imageAnalysis = _analysisResult!['image_analysis'] ?? {};
    final vegetation = imageAnalysis['vegetation_analysis'] ?? {};
    final validation = imageAnalysis['validation'] ?? {};
    final satelliteComparison = _analysisResult!['satellite_comparison'];
    final recommendations = _analysisResult!['recommendations'] ?? [];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kuva-analyysin tulokset',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Biomass estimate
            _buildResultRow(
              '🌱 Biomassa-arvio',
              '${imageAnalysis['biomass_estimate_kg_per_hectare'] ?? 0} kg/ha',
            ),
            
            // Vegetation analysis
            _buildResultRow(
              '🌿 Kasvillisuus',
              '${vegetation['green_percentage'] ?? 0}%',
            ),
            
            _buildResultRow(
              '💚 Kasvillisuuden terveys',
              '${vegetation['vegetation_health_score'] ?? 0}/100',
            ),
            
            // Validation score
            _buildResultRow(
              '✅ Validointi',
              '${validation['overall_score'] ?? 0}/100',
              validation['overall_score'] > 70 ? Colors.green : Colors.orange,
            ),
            
            const SizedBox(height: 16),
            
            // Satellite comparison
            if (satelliteComparison != null) ...[
              const Divider(),
              Text(
                'Satelliittivertailu',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildResultRow(
                '🛰️ Yhdenmukaisuus',
                satelliteComparison['is_consistent'] ? 'Yhdenmukainen' : 'Eroaa',
                satelliteComparison['is_consistent'] ? Colors.green : Colors.red,
              ),
              _buildResultRow(
                '📊 Luottamus',
                '${satelliteComparison['confidence_score']}/100',
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Recommendations
            if (recommendations.isNotEmpty) ...[
              const Divider(),
              Text(
                'Suositukset',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...recommendations.map((rec) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  rec,
                  style: const TextStyle(fontSize: 14),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
        title: Text('Kuva: ${widget.fieldName}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status message
          if (_statusMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: _isLocationValid() ? Colors.green.shade100 : Colors.orange.shade100,
              child: Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isLocationValid() ? Colors.green.shade700 : Colors.orange.shade700,
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
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          
          // Analysis results
          if (_analysisResult != null)
            Expanded(
              flex: 3,
              child: SingleChildScrollView(
                child: _buildAnalysisResults(),
              ),
            ),
          
          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_currentPosition != null)
                  Text(
                    'GPS: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Päivitä GPS'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isLoading || !_isLocationValid() ? null : _takePicture,
                      icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt),
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