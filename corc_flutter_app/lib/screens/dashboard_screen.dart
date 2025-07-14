import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/field.dart';
import '../models/ndvi_data.dart';
import '../widgets/ndvi_chart.dart';
import 'simple_field_mapping_screen.dart';
import 'payments_screen.dart';
import 'simple_photo_capture.dart';
import 'field_corner_photo_capture.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Field> _fields = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final fields = await authService.apiService.getFields();
      setState(() {
        _fields = fields;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load fields: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Fields'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.payments),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentsScreen()),
              );
            },
            tooltip: 'Payments',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.account_circle),
            onSelected: (value) async {
              if (value == 'logout') {
                // Show confirmation dialog
                bool? shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Logout'),
                    content: Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Logout'),
                      ),
                    ],
                  ),
                );
                
                if (shouldLogout == true) {
                  final authService = Provider.of<AuthService>(context, listen: false);
                  await authService.logout();
                  
                  // Force navigation to login and clear all routes
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login', 
                    (Route<dynamic> route) => false,
                  );
                }
              } else if (value == 'profile') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Profile page coming soon!')),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey.shade700),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red.shade600),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _fields.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.terrain,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No fields yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add your first field to start monitoring',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _fields.length,
                  itemBuilder: (context, index) {
                    final field = _fields[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Icon(
                            Icons.terrain,
                            color: Colors.green.shade600,
                          ),
                        ),
                        title: Text(field.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (field.areaHectares != null)
                              Text('${field.areaHectares!.toStringAsFixed(2)} hectares'),
                            Text('Created: ${field.createdAt.day}/${field.createdAt.month}/${field.createdAt.year}'),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navigate to field details
                          _showFieldDetails(field);
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to add field screen
          _showAddFieldDialog();
        },
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('Add Field'),
      ),
    );
  }

  void _showFieldDetails(Field field) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FieldDetailsSheet(field: field),
    );
  }

  Future<void> _showAddFieldDialog() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SimpleFieldMappingScreen()),
    );
    
    // If field was created successfully, reload the fields list
    if (result == true) {
      _loadFields();
    }
  }
}

class _FieldDetailsSheet extends StatefulWidget {
  final Field field;

  const _FieldDetailsSheet({Key? key, required this.field}) : super(key: key);

  @override
  _FieldDetailsSheetState createState() => _FieldDetailsSheetState();
}

class _FieldDetailsSheetState extends State<_FieldDetailsSheet> {
  List<NDVIData> _ndviData = [];
  bool _isLoadingNDVI = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNDVIData();
  }

  Future<void> _loadNDVIData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final ndviData = await authService.apiService.getFieldNDVI(widget.field.id);
      setState(() {
        _ndviData = ndviData;
        _isLoadingNDVI = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingNDVI = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.field.name,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.satellite, color: Colors.green.shade600),
                      SizedBox(width: 8),
                      Text(
                        'Satelliittiseuranta Aktiivinen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Pelloltasi seurataan satelliittien avulla. NDVI-data näyttää kasvillisuuden terveyden.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      if (widget.field.areaHectares != null) ...[
                        Icon(Icons.terrain, color: Colors.green.shade600, size: 20),
                        SizedBox(width: 4),
                        Text('${widget.field.areaHectares!.toStringAsFixed(2)} ha'),
                        SizedBox(width: 16),
                      ],
                      Icon(Icons.location_on, color: Colors.green.shade600, size: 20),
                      SizedBox(width: 4),
                      Text('${widget.field.latitude.toStringAsFixed(4)}, ${widget.field.longitude.toStringAsFixed(4)}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SimplePhotoCaptureScreen(
                          fieldId: widget.field.id,
                          fieldName: widget.field.name,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.camera_alt),
                  label: Text('Ota Kuva'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FieldCornerPhotoCaptureScreen(
                          fieldId: widget.field.id,
                          fieldName: widget.field.name,
                          fieldCoordinates: widget.field.coordinates,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.location_on),
                  label: Text('Kulmat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Expanded(
            child: _isLoadingNDVI
                ? Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 48, color: Colors.red),
                            SizedBox(height: 16),
                            Text(
                              'Virhe ladattaessa NDVI-dataa',
                              style: TextStyle(fontSize: 16, color: Colors.red),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isLoadingNDVI = true;
                                  _error = null;
                                });
                                _loadNDVIData();
                              },
                              child: Text('Yritä uudelleen'),
                            ),
                          ],
                        ),
                      )
                    : Card(
                        child: NDVIChart(
                          ndviData: _ndviData,
                          height: 400,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}