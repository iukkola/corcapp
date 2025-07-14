import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/field.dart';
import '../models/ndvi_data.dart';

class ApiService {
  static const String baseUrl = 'http://91.99.150.88:8000'; // Server IP
  
  String? _token;
  
  void setToken(String token) {
    _token = token;
  }
  
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Auth methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email,
        'password': password,
      },
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Login failed');
    }
  }

  Future<Map<String, dynamic>> register(String email, String password, String language) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _headers,
      body: json.encode({
        'email': email,
        'password': password,
        'language': language,
      }),
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Registration failed');
    }
  }

  // Field methods
  Future<Field> createField(String name, List<List<double>> coordinates, double? areaHectares) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fields'),
      headers: _headers,
      body: json.encode({
        'name': name,
        'coordinates': coordinates,
        'area_hectares': areaHectares,
      }),
    );
    
    if (response.statusCode == 200) {
      return Field.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create field');
    }
  }

  Future<List<Field>> getFields() async {
    final response = await http.get(
      Uri.parse('$baseUrl/fields'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Field.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load fields');
    }
  }

  Future<List<NDVIData>> getFieldNDVI(int fieldId, {int daysBack = 90}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fields/$fieldId/ndvi?days_back=$daysBack'),
      headers: _headers,
    );
    
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => NDVIData.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load NDVI data');
    }
  }

  Future<void> createPlantingReport(int fieldId, String cropType, DateTime plantingDate, String? imageUrl, String? notes) async {
    final response = await http.post(
      Uri.parse('$baseUrl/fields/$fieldId/planting-report'),
      headers: _headers,
      body: json.encode({
        'field_id': fieldId,
        'crop_type': cropType,
        'planting_date': plantingDate.toIso8601String(),
        'image_url': imageUrl,
        'notes': notes,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to create planting report');
    }
  }
}