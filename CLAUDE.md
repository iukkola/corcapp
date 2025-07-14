# CORC Project - Carbon Credit App for Farmers

## Project Status: ENHANCED VERSION READY ✅
**Date:** July 4, 2025
**Next milestone:** University meeting September 2025

## What We Built
- **Backend API** (FastAPI + SQLAlchemy) with Google Earth Engine NDVI integration
- **Flutter mobile app** with working authentication and interactive dashboard
- **NDVI Chart Visualization** - Beautiful interactive charts with FL Chart
- **Demo data** for 5 Kap Verde farmers with realistic NDVI time series
- **Working APK** tested on Android device

## Tech Stack
- **Backend:** Python FastAPI, SQLite, Google Earth Engine API
- **Frontend:** Flutter (Android APK built and tested)
- **Server:** Hetzner Cloud (91.99.150.88)
- **Demo accounts:** antonio.silva@kapverde.com / demo123 (and 4 others)

## Key Features Implemented
1. User authentication (JWT tokens)
2. Field management with GPS coordinates 
3. NDVI calculation from satellite data (Sentinel-2)
4. **Interactive NDVI Charts** - FL Chart powered visualizations with:
   - Time series progression showing vegetation health
   - Color-coded health status indicators
   - Interactive tooltips with detailed info
   - Finnish localized status labels
   - Statistics panel with trends and averages
5. Planting reports with carbon credit tracking
6. Demo data for Kap Verde islands (Santiago, Santo Antão, Fogo)

## Project Vision
- **Target:** Small farmers in Cape Verde
- **Goal:** Incentivize sustainable farming via satellite monitoring + carbon credits
- **Partnership:** Finnish university researching biochar + soil improvement
- **Pilot location:** Cape Verde (poor soil conditions, close to Azores)

## Technical Architecture
```
Flutter App ↔ FastAPI Backend ↔ Google Earth Engine
     ↓              ↓                    ↓
 User Auth     SQLite DB          NDVI Calculation
```

## Demo Flow
1. **Login:** antonio.silva@kapverde.com / demo123
2. **Dashboard:** View farmer's fields with satellite monitoring status
3. **Field Details:** Tap any field to see interactive NDVI chart
4. **Add New Field:** Tap '+' button to access GPS field mapping
5. **Map Field:** Use interactive map to draw field boundaries
6. **Payments:** Access carbon credit balance and payment options via top toolbar
7. **NDVI Analytics:** View detailed vegetation health progression over time

## ✅ Recently Completed (July 4, 2025)

### 📊 NDVI Chart Visualization
- **Interactive FL Chart integration** with:
  - Time series showing vegetation health progression
  - Color-coded status indicators (Erinomainen/Hyvä/Kohtalainen/Huono)
  - Detailed tooltips with NDVI values, dates, and biomass estimates
  - Statistics panel with latest values, averages, and growth trends
  - Finnish localization for farmer-friendly interface

### 🗺️ GPS Field Mapping System 
- **OpenStreetMap-based field boundary drawing** with:
  - Interactive map using flutter_map (100% free)
  - Tap-to-draw field boundaries
  - Real-time area calculation in hectares
  - Automatic polygon validation (minimum 100m²)
  - Visual field numbering and coordinate display
  - Direct integration with backend field creation API

### 💰 Payment System UI
- **Carbon credit payment interface** featuring:
  - Credit balance dashboard with tCO₂ tracking
  - Multiple payment method support (M-Pesa, Bank, Digital Wallet)
  - Transaction history with verification status
  - Cash-out functionality with real-time calculations
  - Payment method connection workflows

## Next Steps (Ideas for continuation)
- **GPS enhancements:** Real-time GPS tracking for precise boundary walking
- **Payment integration:** Live M-Pesa API connection
- **Community features:** Farmer rankings and social features
- **Offline support:** Field mapping without internet connection
- **Advanced analytics:** Soil health predictions and weather integration

## File Locations
- **Backend:** `/root/hiilikrediitti-appi/backend/`
- **Flutter:** `/root/hiilikrediitti-appi/corc_flutter_app/`
- **APK:** `/root/hiilikrediitti-appi/corc_flutter_app/build/app/outputs/flutter-apk/app-debug.apk`
- **Demo script:** `/root/hiilikrediitti-appi/backend/demo_kap_verde.py`

## Running the System
```bash
# Backend
cd /root/hiilikrediitti-appi/backend
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000

# Demo data
python demo_kap_verde.py

# APK download
cd /root/hiilikrediitti-appi/corc_flutter_app/build/app/outputs/flutter-apk
python3 -m http.server 9000
# Download: http://91.99.150.88:9000/app-debug.apk
```

## Demo Accounts
- antonio.silva@kapverde.com / demo123
- maria.santos@kapverde.com / demo123  
- jose.pereira@kapverde.com / demo123
- fatima.rodrigues@kapverde.com / demo123
- manuel.gomes@kapverde.com / demo123

## Google Earth Engine Credentials & Setup

### Project Details
- **Project ID:** `ee-ilkkaukkola`
- **Project URL:** https://code.earthengine.google.com (works in browser)

### OAuth Client Configuration
- **Client ID:** `[REMOVED FOR SECURITY]`
- **Client Secret:** `[REMOVED FOR SECURITY]`
- **Redirect URIs:** http://localhost:8080, https://corcapp.com
- **JavaScript Origins:** http://localhost:8080, https://corcapp.com

### Service Account for Backend
- **Email:** `earth-engine-backend@ee-ilkkaukkola.iam.gserviceaccount.com`
- **Key File:** `/root/hiilikrediitti-appi/backend/service-account-key.json`
- **Roles Required:**
  - Earth Engine Resource Viewer
  - Earth Engine Resource Writer  
  - Service Usage Consumer
  - Project Viewer

### GEE API Status
- ✅ **Earth Engine API:** ENABLED
- ✅ **Authentication:** Service Account working
- ✅ **Test Results:** 53 NDVI datapoints from Azores, 2 from Kap Verde
- ✅ **Satellite Data:** Real Sentinel-2 NDVI calculations working

### Backend Configuration
```python
# In earth_engine_service.py
credentials = ee.ServiceAccountCredentials(
    email='earth-engine-backend@ee-ilkkaukkola.iam.gserviceaccount.com',
    key_file='service-account-key.json'
)
ee.Initialize(credentials, project='ee-ilkkaukkola')
```

## Project Impact
- **Problem:** Poor farmers need incentives for sustainable farming
- **Solution:** Transparent satellite monitoring + micro carbon credit payments
- **Innovation:** Trust through technology without punishment-based systems
- **Research angle:** Biochar + satellite verification for soil carbon sequestration