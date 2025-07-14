# 🌍 CORC PROJECT - MASTER PLAN & ROADMAP
**Carbon Credit App for Farmers**

---

## 📊 PROJECT STATUS: PRODUCTION READY v2.2
**Date:** July 14, 2025  
**Current Phase:** Clean Production Environment + GitHub Backup  
**Next Milestone:** University Meeting September 2025

## 🎯 MISSION & VISION

### Core Mission
Democratize carbon credit access for small farmers in developing countries through transparent satellite monitoring and micro-payment systems.

### Target Impact
- **Who:** Small farmers in Cape Verde (pilot), expanding to Africa
- **Problem:** Complex carbon credit verification processes exclude small farmers
- **Solution:** Simple mobile app + satellite verification + instant payments
- **Innovation:** Trust through technology, not punishment-based monitoring

---

## 📱 VERSION HISTORY & ROADMAP

### v1.0 "Foundation" (June 2025) ✅
- Basic Flutter app with authentication
- FastAPI backend with SQLite
- Google Earth Engine integration
- Demo data for 5 Cape Verde farmers

### v2.0 "Enhanced Dashboard" (July 4, 2025) ✅
- Interactive NDVI charts with FL Chart
- GPS field mapping with OpenStreetMap
- Payment system UI with M-Pesa integration
- Real satellite data integration

### v2.1 "GPS Revolution" (July 10, 2025) ✅
- **BREAKTHROUGH:** Direct GPS collection in Flutter app
- **Nobel-worthy:** Works on ANY Android phone without EXIF settings
- Backend supports JSON GPS coordinates
- Web version with CORS support
- Solves farmer usability problem globally

### **v2.2 "Production Ready" (July 14, 2025) 🚀 CURRENT**
- **MAJOR:** Clean production environment established
- **BACKUP:** Full GitHub repository with secure version control
- **OPTIMIZED:** Server cleaned and minimal footprint (464MB → 458MB)
- **SECURE:** Sensitive data removed from version control
- **AUTOMATED:** Deployment pipeline with ./deploy.sh script
- **STABLE:** API running smoothly at http://91.99.150.88:8000
- **MOBILE:** Existing mobile app continues working seamlessly

### v2.3 "Enhanced Features" (August 2025) 🎯 NEXT
- Enhanced APK with improved GPS functionality
- Optimized for low-end Android devices
- Offline field mapping capability
- Better error handling and user feedback

### v3.0 "Market Launch" (September 2025) 🌟 TARGET
- Live M-Pesa payment integration
- Multi-language support (Portuguese, Kriolu)
- Community features & farmer rankings
- University partnership integration

---

## 🛠️ DEVELOPMENT SETUP (Updated July 14, 2025)

### Local Development Environment
```bash
# Clone from GitHub
git clone https://github.com/iukkola/corcapp.git
cd corcapp

# Backend setup
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.local .env
uvicorn main:app --reload

# Flutter setup
cd ../corc_flutter_app
flutter pub get
flutter run
```

### Deployment to Production
```bash
# Automated deployment
./deploy.sh

# Manual deployment
./deploy.sh --with-flutter
```

### Important Files & Locations
- **GitHub Repository:** https://github.com/iukkola/corcapp
- **Production Server:** root@co2 (91.99.150.88)
- **API Endpoint:** http://91.99.150.88:8000
- **Database Backup:** /root/corc_production_backup.db
- **GEE Keys Backup:** /root/gee_key_backup.json

### Development Guidelines
- Always work locally first
- Use deployment script for production updates
- Never commit sensitive data (automated GitHub security prevents this)
- Mobile app API endpoint remains stable at port 8000

---

**🌟 CORC Project: Revolutionizing Agriculture Through Technology**  
*Making carbon credits accessible to every farmer, everywhere.*

**Last Updated:** July 14, 2025  
**Next Review:** July 21, 2025  
**Document Version:** 2.2.0
EOF < /dev/null
