# CORC University Research Tool - Development Plan

## 🎯 Vision: Field Corner Photo Capture System for University Research

**Date:** July 10, 2025  
**Goal:** Transform CORC into a comprehensive research tool for universities studying biochar, soil improvement, and carbon sequestration

## 📋 Current State Analysis - EXCELLENT FOUNDATION

### ✅ Already Implemented
- **GPS Integration:** `field_photo_capture.dart` has full GPS functionality
- **Image Analysis:** `image_analysis_service.py` reads GPS coordinates from EXIF data  
- **Location Validation:** 100m radius validation working
- **Biomass Calculation:** Image-based biomass estimation algorithm
- **Satellite Comparison:** NDVI vs photo analysis comparison
- **Backend Infrastructure:** FastAPI with Google Earth Engine integration

### 🔧 Current Issue
- GPS packages commented out in `pubspec.yaml` (easy fix)
- Need to uncomment: `camera`, `geolocator`, `permission_handler`

## 🏗️ Development Roadmap

### **Phase 1: Activate GPS System (1 day)**
**Status:** Ready to implement

**Tasks:**
1. Uncomment GPS packages in `pubspec.yaml`
2. Test existing GPS functionality in `field_photo_capture.dart`
3. Verify GPS coordinate embedding in photos
4. Ensure backend GPS validation works

**Expected Outcome:** Working GPS photo capture system

### **Phase 2: Field Corner Capture System (2-3 days)**
**Status:** Next priority

**Feature Design:**
```
Field Corner Navigation System:
┌─────────────────────────────────┐
│ Kulma 1: NE (koillinen)  📍     │
│ GPS: 14.123456, -23.456789      │
│ Etäisyys: 15m koilliskulmaan    │
│ [Ota kuva] [Seuraava kulma]     │
└─────────────────────────────────┘
```

**Implementation:**
- Corner navigator: "Mene kentän koilliskulmaan"
- GPS distance measurement: Real-time distance to target corner
- Corner marking: "Kulma 1/4 tallennettu ✅"
- Photo validation: GPS coordinates + visual analysis

### **Phase 3: University Research Features (3-5 days)**
**Status:** Design phase

**Research Tools:**
1. **Data Export System**
   - CSV/JSON export for research analysis
   - GPS coordinates, timestamps, biomass estimates
   - NDVI correlation data

2. **Biomass Calibration Tool**
   - Compare image estimates with real field samples
   - Calibration coefficients for different crop types
   - Validation scoring system

3. **Statistical Analysis Dashboard**
   - Correlation graphs: Image vs Satellite vs Reality
   - Trend analysis over time
   - Biochar impact measurement

### **Phase 4: Advanced Biomass Calculation (5-7 days)**
**Status:** Future development

**Enhancements:**
- Machine learning model for image recognition
- Multi-spectral analysis simulation
- Crop-specific biomass algorithms
- Weather data integration

## 🎓 University Research Applications

### **Primary Research Questions:**
1. **Accuracy Question:** How accurate is image-based biomass estimation?
2. **Biochar Impact:** How does biochar affect NDVI progression over time?
3. **Farmer Reliability:** Can farmers produce reliable scientific data?
4. **Scaling Question:** What's the optimal payment model for carbon credits?

### **Use Cases:**
- **Agricultural Research:** Soil improvement studies
- **Environmental Science:** Carbon sequestration measurement
- **Development Programs:** Farmer incentive optimization
- **Climate Research:** Satellite validation studies

### **Research Output:**
- Peer-reviewed publications
- Conference presentations
- Policy recommendations
- Scalable implementation models

## 🔬 Technical Architecture for Research

### **Data Collection Points:**
```
Field Corner Photos (4 per field):
├── GPS Coordinates (lat, lon, altitude)
├── Timestamp (UTC)
├── Biomass Estimate (kg/ha)
├── Vegetation Analysis (%, density, health)
├── Photo Quality Score (0-100)
└── Satellite NDVI Comparison
```

### **Research Database Schema:**
```sql
research_data_points:
- field_id, corner_id, timestamp
- gps_lat, gps_lon, gps_accuracy
- biomass_estimate, confidence_score
- satellite_ndvi, ndvi_date
- photo_validation_score
- weather_conditions, soil_type
```

### **Export Formats:**
- **CSV:** For Excel/R/Python analysis
- **JSON:** For web applications
- **GeoJSON:** For GIS analysis
- **Research API:** For real-time data access

## 🌍 Global Impact Potential

### **Pilot Location: Cape Verde**
- Poor soil conditions - perfect for biochar testing
- Small field sizes - ideal for photo validation
- Limited infrastructure - mobile-first approach works
- Portuguese/Creole language - achievable localization

### **Scalability:**
- **Technical:** Cloud-based, mobile-first architecture
- **Economic:** Low-cost satellite monitoring
- **Social:** Community-based validation
- **Academic:** Multi-university collaboration

### **Business Model:**
- **University Licensing:** Annual research licenses
- **Data Services:** Aggregated research data sales
- **Consulting:** Implementation support
- **Government Contracts:** Policy development support

## 📈 Success Metrics

### **Technical Metrics:**
- GPS accuracy: <10m error rate
- Photo validation: >80% success rate
- Biomass correlation: R² > 0.7 with satellite data
- System uptime: >95%

### **Research Metrics:**
- Published papers: 2-3 per year
- University partnerships: 5-10 institutions
- Field trials: 100+ farmers
- Data points: 10,000+ validated samples

### **Impact Metrics:**
- Carbon sequestration: Measurable increases
- Farmer income: 15-20% improvement
- Soil health: Documented improvements
- Policy influence: Government adoption

## 🚀 Immediate Next Steps

1. **Activate GPS packages** (Today)
2. **Test current GPS functionality** (Tomorrow)
3. **Design corner capture UI** (This week)
4. **Implement corner navigation** (Next week)
5. **Add research data export** (Following week)

## 📝 Development Notes

**Current Working Directory:** `/root/hiilikrediitti-appi/`

**Key Files:**
- `corc_flutter_app/pubspec.yaml` - GPS packages to uncomment
- `corc_flutter_app/lib/screens/field_photo_capture.dart` - GPS implementation
- `backend/image_analysis_service.py` - Photo analysis with GPS
- `backend/demo_kap_verde.py` - Test data generator

**Test Accounts:**
- antonio.silva@kapverde.com / demo123
- maria.santos@kapverde.com / demo123

**Infrastructure:**
- Server: Hetzner Cloud (91.99.150.88:8000)
- Database: SQLite (easily upgradeable)
- Google Earth Engine: Service account configured

---

**Built with ❤️ for sustainable farming research and university collaboration**