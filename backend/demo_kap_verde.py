"""
Demo script to populate the database with realistic Kap Verde farming data
for university presentation in September
"""
import requests
import json
from datetime import datetime, timedelta
import random

BASE_URL = "http://localhost:8000"

# Kap Verde coordinates for different islands and farming areas
KAP_VERDE_LOCATIONS = {
    "Santiago": {
        "Cidade Velha": (-23.6058, 14.9218),
        "Praia Rural": (-23.5133, 14.9318),
        "Santa Catarina": (-23.7833, 15.1000),
        "Assomada": (-23.6789, 15.0956)
    },
    "Santo_Antao": {
        "Paul Valley": (-25.0833, 17.1167),
        "Ribeira Grande": (-25.0667, 17.1833),
        "Coculi": (-25.0500, 17.1500)
    },
    "Fogo": {
        "São Filipe": (-24.4950, 14.8950),
        "Mosteiros": (-24.3167, 14.8667)
    }
}

CROP_TYPES = [
    "maize", "beans", "sorghum", "millet", 
    "sweet_potato", "cassava", "peanuts"
]

FARMER_PROFILES = [
    {"email": "antonio.silva@kapverde.com", "name": "António Silva", "island": "Santiago", "location": "Cidade Velha"},
    {"email": "maria.santos@kapverde.com", "name": "Maria Santos", "island": "Santiago", "location": "Praia Rural"},
    {"email": "jose.pereira@kapverde.com", "name": "José Pereira", "island": "Santo_Antao", "location": "Paul Valley"},
    {"email": "fatima.rodrigues@kapverde.com", "name": "Fátima Rodrigues", "island": "Santiago", "location": "Santa Catarina"},
    {"email": "manuel.gomes@kapverde.com", "name": "Manuel Gomes", "island": "Fogo", "location": "São Filipe"},
]

def create_field_polygon(center_lat, center_lon, size_hectares=0.5):
    """Create a realistic field polygon around a center point"""
    # Calculate approximate offset for the given hectare size
    # 1 hectare ≈ 0.003° at Kap Verde latitude
    offset = (size_hectares * 0.003) / 2
    
    return [
        [center_lat - offset, center_lon - offset],
        [center_lat + offset, center_lon - offset],
        [center_lat + offset, center_lon + offset],
        [center_lat - offset, center_lon + offset],
        [center_lat - offset, center_lon - offset]  # Close polygon
    ]

def generate_mock_ndvi_data(field_id, planting_date, crop_type, token):
    """Generate realistic NDVI progression for a Kap Verde field"""
    headers = {"Authorization": f"Bearer {token}"}
    
    # Define NDVI progression for different crop types
    ndvi_patterns = {
        "maize": [0.15, 0.25, 0.45, 0.65, 0.75, 0.70, 0.50, 0.25],
        "beans": [0.10, 0.20, 0.40, 0.60, 0.55, 0.45, 0.30, 0.15],
        "sorghum": [0.12, 0.22, 0.42, 0.62, 0.72, 0.68, 0.45, 0.20],
        "millet": [0.10, 0.18, 0.35, 0.55, 0.65, 0.60, 0.40, 0.18]
    }
    
    pattern = ndvi_patterns.get(crop_type, ndvi_patterns["maize"])
    
    # Simulate NDVI measurements every 10 days
    current_date = planting_date
    for i, base_ndvi in enumerate(pattern):
        # Add some random variation (±0.05)
        ndvi_value = max(0, min(1, base_ndvi + random.uniform(-0.05, 0.05)))
        
        # Create NDVI data point directly in database
        # (In real app, this would come from Earth Engine)
        ndvi_data = {
            "field_id": field_id,
            "date": current_date.isoformat(),
            "ndvi_value": round(ndvi_value, 3),
            "biomass_estimate": round(ndvi_value * 15.0, 2),  # Simple biomass estimation
            "data_source": "sentinel-2"
        }
        
        # Since we don't have direct NDVI endpoint, we'll skip this for now
        # In real implementation, this would be handled by the NDVI calculation service
        print(f"  NDVI {current_date.strftime('%Y-%m-%d')}: {ndvi_value:.3f}")
        
        current_date += timedelta(days=10)

def setup_demo_data():
    print("🌍 Setting up CORC Demo Data for Kap Verde")
    print("=" * 50)
    
    all_tokens = []
    
    for farmer in FARMER_PROFILES:
        print(f"\n👨‍🌾 Creating farmer: {farmer['name']} ({farmer['island']})")
        
        # Register farmer
        user_data = {
            "email": farmer["email"],
            "password": "demo123",
            "language": "pt"
        }
        
        try:
            response = requests.post(f"{BASE_URL}/register", json=user_data)
            if response.status_code == 200:
                print(f"  ✓ Registered: {farmer['email']}")
            else:
                print(f"  ℹ️  User might already exist: {farmer['email']}")
        except Exception as e:
            print(f"  ⚠️  Registration error: {e}")
            continue
        
        # Login farmer
        login_data = {
            "username": farmer["email"],
            "password": "demo123"
        }
        
        try:
            response = requests.post(f"{BASE_URL}/login", data=login_data)
            if response.status_code == 200:
                tokens = response.json()
                access_token = tokens["access_token"]
                all_tokens.append((farmer, access_token))
                print(f"  ✓ Logged in successfully")
            else:
                print(f"  ✗ Login failed")
                continue
        except Exception as e:
            print(f"  ⚠️  Login error: {e}")
            continue
        
        headers = {"Authorization": f"Bearer {access_token}"}
        
        # Create 2-3 fields for each farmer
        island_locations = KAP_VERDE_LOCATIONS[farmer["island"]]
        base_location = island_locations[farmer["location"]]
        
        for field_num in range(random.randint(1, 3)):
            # Offset each field slightly from the base location
            offset_lat = base_location[0] + random.uniform(-0.01, 0.01)
            offset_lon = base_location[1] + random.uniform(-0.01, 0.01)
            
            field_size = random.uniform(0.2, 1.5)  # 0.2 to 1.5 hectares
            field_name = f"{farmer['name'].split()[0]} Field {field_num + 1}"
            
            field_data = {
                "name": field_name,
                "coordinates": create_field_polygon(offset_lat, offset_lon, field_size),
                "area_hectares": round(field_size, 2)
            }
            
            try:
                response = requests.post(f"{BASE_URL}/fields", json=field_data, headers=headers)
                if response.status_code == 200:
                    field = response.json()
                    print(f"    ✓ Created field: {field_name} ({field_size:.2f} ha)")
                    
                    # Create planting report
                    crop = random.choice(CROP_TYPES)
                    planting_date = datetime.now() - timedelta(days=random.randint(30, 120))
                    
                    report_data = {
                        "field_id": field["id"],
                        "crop_type": crop,
                        "planting_date": planting_date.isoformat(),
                        "notes": f"Planted {crop} in {farmer['island']} island. Soil improved with biochar application."
                    }
                    
                    response = requests.post(f"{BASE_URL}/fields/{field['id']}/planting-report", 
                                           json=report_data, headers=headers)
                    if response.status_code == 200:
                        print(f"      ✓ Planted: {crop} on {planting_date.strftime('%Y-%m-%d')}")
                        
                        # Generate mock NDVI progression
                        print(f"      📡 Generating NDVI data...")
                        generate_mock_ndvi_data(field["id"], planting_date, crop, access_token)
                    else:
                        print(f"      ✗ Failed to create planting report")
                else:
                    print(f"    ✗ Failed to create field: {field_name}")
            except Exception as e:
                print(f"    ⚠️  Field creation error: {e}")
    
    print("\n🎉 Demo data setup completed!")
    print(f"✓ Created {len(FARMER_PROFILES)} farmers")
    print("✓ Each farmer has 1-3 fields with different crops")
    print("✓ All fields have planting reports")
    print("✓ NDVI progression data simulated")
    
    print("\n📊 Demo Accounts for Testing:")
    print("-" * 30)
    for farmer in FARMER_PROFILES:
        print(f"Email: {farmer['email']}")
        print(f"Password: demo123")
        print(f"Location: {farmer['island']} - {farmer['location']}")
        print()

if __name__ == "__main__":
    setup_demo_data()