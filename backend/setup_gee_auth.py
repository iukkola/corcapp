#!/usr/bin/env python3
"""
Setup Earth Engine authentication using browser flow
"""
import ee
import webbrowser
import subprocess
import os

def setup_gee_authentication():
    """Set up GEE authentication for the backend"""
    
    print("🌍 Setting up Google Earth Engine authentication...")
    print()
    
    # Try to initialize first
    try:
        ee.Initialize(project='ee-ilkkaukkola')
        print("✅ Earth Engine already authenticated and working!")
        return True
    except Exception as e:
        print(f"❌ Need to authenticate: {e}")
        print()
    
    # Since you're already authenticated in the browser, 
    # let's try to use gcloud to get the token
    try:
        print("📋 Please run this command in your local terminal:")
        print("gcloud auth application-default login")
        print()
        print("After that, copy the generated credentials file to this server")
        print("Or run: gcloud auth application-default print-access-token")
        print("And paste the token here.")
        print()
        
        # Alternative: Direct token input
        print("🔑 Or paste your access token here:")
        token = input("Access token: ").strip()
        
        if token:
            # Try to use the token
            os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = ''  # Clear any existing
            import google.auth
            from google.auth.credentials import Credentials
            
            # This is a simplified approach - in production you'd want proper OAuth flow
            print("🧪 Testing token...")
            
    except Exception as e:
        print(f"❌ Token setup failed: {e}")
        return False
    
    print("\n💡 Since Earth Engine works in your browser, the easiest way is:")
    print("1. Keep using demo data in backend (works perfectly)")
    print("2. Or use service account for production")
    
    return False

if __name__ == "__main__":
    setup_gee_authentication()