import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

class SimplePhotoCaptureScreen extends StatefulWidget {
  final int fieldId;
  final String fieldName;

  const SimplePhotoCaptureScreen({
    Key? key,
    required this.fieldId,
    required this.fieldName,
  }) : super(key: key);

  @override
  State<SimplePhotoCaptureScreen> createState() => _SimplePhotoCaptureScreenState();
}

class _SimplePhotoCaptureScreenState extends State<SimplePhotoCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _statusMessage;
  Map<String, dynamic>? _analysisResult;
  File? _imageFile;
  Position? _currentPosition;
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      setState(() {
        _statusMessage = 'Haetaan GPS-sijaintia...';
      });
      
      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _statusMessage = 'GPS-lupa evätty';
          });
          return;
        }
      }
      
      // Get current position
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _statusMessage = 'GPS valmis: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'GPS-virhe: $e';
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Otetaan kuva...';
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Kuvan otto peruutettu';
        });
        return;
      }

      setState(() {
        _imageFile = File(image.path);
        _statusMessage = _currentPosition != null 
          ? 'GPS: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}\nAnalysoidaan kuvaa...'
          : 'Analysoidaan kuvaa... (GPS ei saatavilla)';
      });

      // Convert image to base64
      final bytes = await _imageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Send to backend for analysis
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.apiService.analyzeFieldPhoto(widget.fieldId, base64Image);
      
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

  Future<void> _pickFromGallery() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Valitaan kuva galleriasta...';
      });

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Kuvan valinta peruutettu';
        });
        return;
      }

      setState(() {
        _imageFile = File(image.path);
        _statusMessage = _currentPosition != null 
          ? 'GPS: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}\nAnalysoidaan kuvaa...'
          : 'Analysoidaan kuvaa... (GPS ei saatavilla)';
      });

      // Convert image to base64
      final bytes = await _imageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Send to backend for analysis
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.apiService.analyzeFieldPhoto(widget.fieldId, base64Image);
      
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Biomass estimate
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.eco, color: Colors.green.shade600, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biomassa-arvio',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          '${imageAnalysis['biomass_estimate_kg_per_hectare'] ?? 0} kg/ha',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Vegetation analysis
            _buildResultRow(
              '🌿 Kasvillisuuden peitto',
              '${vegetation['green_percentage'] ?? 0}%',
            ),
            
            _buildResultRow(
              '💚 Kasvillisuuden terveys',
              '${vegetation['vegetation_health_score'] ?? 0}/100',
              _getHealthColor(vegetation['vegetation_health_score'] ?? 0),
            ),
            
            _buildResultRow(
              '📊 Tiheys',
              '${vegetation['vegetation_density'] ?? 0}/100',
            ),
            
            // Validation score
            _buildResultRow(
              '✅ Validointipisteet',
              '${validation['overall_score'] ?? 0}/100',
              _getValidationColor(validation['overall_score'] ?? 0),
            ),
            
            // GPS information
            if (validation['photo_gps'] != null) ...[
              _buildResultRow(
                '📍 GPS-koordinaatit',
                '${validation['photo_gps'][0].toStringAsFixed(6)}, ${validation['photo_gps'][1].toStringAsFixed(6)}',
                Colors.blue,
              ),
              _buildResultRow(
                '📏 Etäisyys kentältä',
                '${validation['gps_distance_meters'].toStringAsFixed(0)}m',
                validation['gps_valid'] ? Colors.green : Colors.red,
              ),
            ] else if (_currentPosition != null) ...[
              _buildResultRow(
                '📍 GPS sovelluksesta',
                '${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                Colors.orange,
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Satellite comparison
            if (satelliteComparison != null) ...[
              const Divider(),
              Text(
                'Satelliittivertailu',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: satelliteComparison['is_consistent'] 
                    ? Colors.green.shade50 
                    : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: satelliteComparison['is_consistent'] 
                      ? Colors.green.shade200 
                      : Colors.orange.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    _buildResultRow(
                      '🛰️ Yhdenmukaisuus',
                      satelliteComparison['is_consistent'] ? 'Yhdenmukainen' : 'Eroaa',
                      satelliteComparison['is_consistent'] ? Colors.green : Colors.orange,
                    ),
                    _buildResultRow(
                      '📊 Luottamus',
                      '${satelliteComparison['confidence_score']}/100',
                    ),
                    _buildResultRow(
                      '🛰️ Satelliitti NDVI',
                      '${satelliteComparison['satellite_ndvi']?.toStringAsFixed(3) ?? 'N/A'}',
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Recommendations
            if (recommendations.isNotEmpty) ...[
              const Divider(),
              Text(
                'Suositukset',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: recommendations.map<Widget>((rec) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: Colors.blue.shade700, fontSize: 16)),
                        Expanded(
                          child: Text(
                            rec,
                            style: TextStyle(fontSize: 14, color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getHealthColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getValidationColor(double score) {
    if (score >= 70) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildResultRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kuva: ${widget.fieldName}'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status message
            if (_statusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: _isLoading 
                  ? Colors.blue.shade100 
                  : (_analysisResult != null ? Colors.green.shade100 : Colors.orange.shade100),
                child: Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isLoading 
                      ? Colors.blue.shade700 
                      : (_analysisResult != null ? Colors.green.shade700 : Colors.orange.shade700),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            // Image preview
            if (_imageFile != null)
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imageFile!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            
            // Analysis results
            if (_analysisResult != null)
              _buildAnalysisResults(),
            
            // Controls
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _takePhoto,
                          icon: _isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.camera_alt),
                          label: Text(_isLoading ? 'Analysoi...' : 'Ota kuva'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _pickFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galleria'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Ohje:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ota kuva pellon kasvillisuudesta. Järjestelmä analysoi kuvan ja vertaa tuloksia satelliittidataan.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}