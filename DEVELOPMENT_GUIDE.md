# CORC App - Kehitysopas

## 🚀 Paikallinen kehitysympäristö

### Vaatimukset
- **Python 3.8+** (backend)
- **Flutter 3.10+** (mobiiliappi)
- **Git** (versionhallinta)

### Backend-kehitys

1. **Asenna riippuvuudet:**
```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # Mac/Linux
pip install -r requirements.txt
```

2. **Kopioi ympäristötiedosto:**
```bash
cp .env.local .env
```

3. **Käynnistä kehityspalvelin:**
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Flutter-kehitys

1. **Asenna riippuvuudet:**
```bash
cd corc_flutter_app
flutter pub get
```

2. **Vaihda API-osoite kehitykseen:**
Muokkaa `lib/services/api_service.dart`:
```dart
static const String baseUrl = 'http://localhost:8000';  // Kehitys
// static const String baseUrl = 'http://91.99.150.88:8000';  // Tuotanto
```

3. **Käynnistä Flutter:**
```bash
# Android-emulaattori
flutter run

# iOS-simulaattori
flutter run -d ios

# Web-versio
flutter run -d chrome
```

## 📱 Mobiiliappin testaus

### Android APK:n rakentaminen
```bash
cd corc_flutter_app
flutter build apk --debug  # Kehitysversio
flutter build apk --release  # Julkaisuversio
```

APK löytyy: `build/app/outputs/flutter-apk/`

### Tärkeää mobiiliappille:
- API-osoite pysyy: `http://91.99.150.88:8000`
- GPS-luvat vaaditaan (Android 6.0+)
- Internetyhteys pakollinen

## 🚢 Deployment tuotantoon

### Automaattinen deployment
```bash
# Pelkkä backend
./deploy.sh

# Backend + Flutter web
./deploy.sh --with-flutter
```

### Manuaalinen deployment
```bash
# 1. Kopioi tiedostot
rsync -avz --exclude 'venv' --exclude '__pycache__' \
  backend/ root@co2:/root/hiilikrediitti-appi/backend/

# 2. Kirjaudu palvelimelle
ssh root@co2

# 3. Käynnistä backend uudelleen
cd /root/hiilikrediitti-appi/backend
pkill -f "uvicorn main:app"
source venv/bin/activate
nohup uvicorn main:app --host 0.0.0.0 --port 8000 > server.log 2>&1 &
```

## 🔑 Salaisuudet ja avaimet

### Google Earth Engine
- Service Account: `earth-engine-backend@ee-ilkkaukkola.iam.gserviceaccount.com`
- Avaintiedosto: `backend/service-account-key.json`
- Projekti: `ee-ilkkaukkola`

### Tietoturva
- ÄLÄ commitoi `.env` tiedostoja
- ÄLÄ commitoi `service-account-key.json`
- Vaihda `SECRET_KEY` tuotannossa

## 📊 Tietokanta

### SQLite-tiedosto
- Sijainti: `backend/users.db`
- ÄLÄ kopioi tuotannon tietokantaa kehitykseen

### Demo-datan luonti
```bash
cd backend
python demo_kap_verde.py
```

Luo 5 demo-käyttäjää Kap Verden saarilta.

## 🐛 Vianetsintä

### Backend ei käynnisty
```bash
# Tarkista virheloki
tail -f backend/server.log

# Tarkista portti
lsof -i :8000
```

### Flutter-virheet
```bash
# Puhdista cache
flutter clean
flutter pub get

# Päivitä riippuvuudet
flutter pub upgrade
```

### Mobiiliappi ei yhdistä
1. Tarkista API-osoite: `http://91.99.150.88:8000`
2. Varmista internetluvat AndroidManifest.xml:ssä
3. Testaa API selaimella

## 📝 Commit-käytännöt

```bash
# Hyvä commit-viesti
git commit -m "Add GPS coordinate validation for field mapping"

# Huono commit-viesti
git commit -m "fix stuff"
```

## 🆘 Tuki

- Master Plan: `CORC_MASTER_PLAN.md`
- Tekniset tiedot: `CLAUDE.md`
- Palvelin: `ssh root@co2` (91.99.150.88)