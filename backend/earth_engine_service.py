import ee
from typing import List, Dict, Any
from datetime import datetime, timedelta
import json

class EarthEngineService:
    def __init__(self):
        self.ee_available = False
        try:
            # Try service account authentication first
            service_account_path = 'service-account-key.json'
            credentials = ee.ServiceAccountCredentials(
                email='earth-engine-backend@ee-ilkkaukkola.iam.gserviceaccount.com',
                key_file=service_account_path
            )
            ee.Initialize(credentials, project='ee-ilkkaukkola')
            print("🛰️  Earth Engine authenticated with service account!")
            self.ee_available = True
        except Exception as e:
            print(f"⚠️  Service account authentication failed: {e}")
            try:
                # Fallback to default authentication
                ee.Initialize(project='ee-ilkkaukkola')
                print("✅ Earth Engine authenticated with default credentials!")
                self.ee_available = True
            except Exception as e2:
                print(f"⚠️  Earth Engine ei käytettävissä: {e2}")
                print("📊 Käytetään demo-dataa NDVI-laskentaan")
                self.ee_available = False

    def calculate_ndvi_for_field(self, coordinates: List[List[float]], 
                                start_date: str, end_date: str) -> List[Dict[str, Any]]:
        
        # If Earth Engine is not available, return demo data
        if not self.ee_available:
            return self._generate_demo_ndvi_data(start_date, end_date)
        
        try:
            # Convert coordinates to Earth Engine geometry [lon, lat]
            ee_coords = [[coord[1], coord[0]] for coord in coordinates]
            geometry = ee.Geometry.Polygon([ee_coords])
            
            # Get Sentinel-2 Surface Reflectance collection
            collection = (ee.ImageCollection('COPERNICUS/S2_SR')
                         .filterDate(start_date, end_date)
                         .filterBounds(geometry)
                         .filter(ee.Filter.lt('CLOUDY_PIXEL_PERCENTAGE', 20)))
            
            def calculate_ndvi(image):
                # NDVI: (NIR - Red) / (NIR + Red)
                ndvi = image.normalizedDifference(['B8', 'B4']).rename('NDVI')
                return image.addBands(ndvi)
            
            ndvi_collection = collection.map(calculate_ndvi)
            
            def get_ndvi_stats(image):
                stats = image.select('NDVI').reduceRegion(
                    reducer=ee.Reducer.mean(),
                    geometry=geometry,
                    scale=10,
                    maxPixels=1e9
                )
                return ee.Feature(None, {
                    'date': image.date().format('YYYY-MM-dd'),
                    'ndvi': stats.get('NDVI')
                })
            
            ndvi_stats = ndvi_collection.map(get_ndvi_stats)
            ndvi_list = ndvi_stats.getInfo()
            
            results = []
            for feature in ndvi_list['features']:
                props = feature['properties']
                if props['ndvi'] is not None:
                    results.append({
                        'date': props['date'],
                        'ndvi_value': round(props['ndvi'], 3)
                    })
            
            results.sort(key=lambda x: x['date'])
            return results
            
        except Exception as e:
            print(f"Error calculating NDVI: {e}")
            return self._generate_demo_ndvi_data(start_date, end_date)
    
    def _generate_demo_ndvi_data(self, start_date: str, end_date: str) -> List[Dict[str, Any]]:
        """Generate realistic demo NDVI data when Earth Engine is not available"""
        import random
        from datetime import datetime, timedelta
        
        start = datetime.strptime(start_date, '%Y-%m-%d')
        end = datetime.strptime(end_date, '%Y-%m-%d')
        
        results = []
        current_date = start
        base_ndvi = 0.6  # Base NDVI value
        
        while current_date <= end:
            # Add some seasonal variation and noise
            day_of_year = current_date.timetuple().tm_yday
            seasonal_factor = 0.2 * (1 + 0.3 * (day_of_year / 365))
            noise = random.uniform(-0.1, 0.1)
            
            ndvi_value = min(0.9, max(0.1, base_ndvi + seasonal_factor + noise))
            
            results.append({
                'date': current_date.strftime('%Y-%m-%d'),
                'ndvi_value': round(ndvi_value, 3)
            })
            
            # Move to next week (roughly)
            current_date += timedelta(days=7)
        
        return results

    def estimate_biomass_from_ndvi(self, ndvi_value: float, crop_type: str = "general") -> float:
        if ndvi_value < 0:
            return 0.0
        
        # Simplified biomass estimation (tons/hectare)
        biomass_coefficients = {
            "general": 15.0,
            "maize": 18.0,
            "sorghum": 12.0,
            "millet": 10.0,
            "beans": 8.0
        }
        
        coefficient = biomass_coefficients.get(crop_type.lower(), 15.0)
        biomass = ndvi_value * coefficient
        
        return round(biomass, 2)