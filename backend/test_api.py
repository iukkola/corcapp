import requests
import json

BASE_URL = "http://localhost:8000"

def test_api():
    # Test 1: Register a user
    print("Testing user registration...")
    user_data = {
        "email": "farmer@kapverde.cv",
        "password": "testpass123",
        "language": "pt"
    }
    
    response = requests.post(f"{BASE_URL}/register", json=user_data)
    if response.status_code == 200:
        print("✓ User registration successful")
        user = response.json()
        print(f"  User ID: {user['id']}, Email: {user['email']}")
    else:
        print(f"✗ User registration failed: {response.status_code}")
        print(response.text)
        return
    
    # Test 2: Login
    print("\nTesting login...")
    login_data = {
        "username": user_data["email"],
        "password": user_data["password"]
    }
    
    response = requests.post(f"{BASE_URL}/login", data=login_data)
    if response.status_code == 200:
        print("✓ Login successful")
        tokens = response.json()
        access_token = tokens["access_token"]
        print(f"  Token received: {access_token[:20]}...")
    else:
        print(f"✗ Login failed: {response.status_code}")
        return
    
    # Test 3: Create a field (Kap Verde coordinates)
    print("\nTesting field creation...")
    headers = {"Authorization": f"Bearer {access_token}"}
    
    # Sample coordinates for a small field in Santiago, Kap Verde
    field_data = {
        "name": "Test Field Santiago",
        "coordinates": [
            [-23.6058, 14.9218],  # lat, lon format
            [-23.6055, 14.9218],
            [-23.6055, 14.9215],
            [-23.6058, 14.9215],
            [-23.6058, 14.9218]   # close the polygon
        ],
        "area_hectares": 0.5
    }
    
    response = requests.post(f"{BASE_URL}/fields", json=field_data, headers=headers)
    if response.status_code == 200:
        print("✓ Field creation successful")
        field = response.json()
        print(f"  Field ID: {field['id']}, Name: {field['name']}")
        field_id = field['id']
    else:
        print(f"✗ Field creation failed: {response.status_code}")
        print(response.text)
        return
    
    # Test 4: Get user fields
    print("\nTesting field retrieval...")
    response = requests.get(f"{BASE_URL}/fields", headers=headers)
    if response.status_code == 200:
        print("✓ Field retrieval successful")
        fields = response.json()
        print(f"  Found {len(fields)} field(s)")
    else:
        print(f"✗ Field retrieval failed: {response.status_code}")
    
    # Test 5: Create planting report
    print("\nTesting planting report...")
    report_data = {
        "field_id": field_id,
        "crop_type": "maize",
        "planting_date": "2024-01-15T10:00:00",
        "notes": "First planting of the season"
    }
    
    response = requests.post(f"{BASE_URL}/fields/{field_id}/planting-report", json=report_data, headers=headers)
    if response.status_code == 200:
        print("✓ Planting report creation successful")
        report = response.json()
        print(f"  Report ID: {report['id']}, Crop: {report['crop_type']}")
    else:
        print(f"✗ Planting report failed: {response.status_code}")
        print(response.text)
    
    print("\n🎉 All basic API tests completed!")

if __name__ == "__main__":
    test_api()