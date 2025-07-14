#!/usr/bin/env python3
import ee
import os

# Try to authenticate with existing credentials first
try:
    ee.Initialize(project='ee-ilkkaukkola')
    print("✅ Earth Engine already authenticated!")
except Exception as e:
    print(f"❌ Authentication failed: {e}")
    print("\nYou need to run manual authentication:")
    print("1. Go to: https://code.earthengine.google.com")
    print("2. Run this code in the Code Editor:")
    print("   print('Hello Earth Engine!')")
    print("3. This will authenticate your Google account")
    print("4. Then come back here")
    
    # Try to create a simple token file
    try:
        # Create EE config directory
        os.makedirs(os.path.expanduser('~/.config/earthengine'), exist_ok=True)
        
        # Create a simple credentials file
        token_data = {
            "client_id": "your-client-id-here",
            "client_secret": "your-client-secret-here",
            "refresh_token": "PLACEHOLDER",
            "type": "authorized_user"
        }
        
        import json
        with open(os.path.expanduser('~/.config/earthengine/credentials'), 'w') as f:
            json.dump(token_data, f)
        
        print("\n🔧 Created credentials template. You'll need to get a refresh token manually.")
        
    except Exception as e2:
        print(f"Could not create credentials file: {e2}")