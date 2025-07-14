#!/usr/bin/env python3
import ee
import json
from google.auth.transport.requests import Request
from google_auth_oauthlib.flow import InstalledAppFlow

# Load credentials
with open('credentials.json', 'r') as f:
    credentials_info = json.load(f)

# Set up OAuth flow with redirect URI
flow = InstalledAppFlow.from_client_config(
    credentials_info,
    scopes=['https://www.googleapis.com/auth/earthengine'],
    redirect_uri='http://localhost:8080'
)

# Get authorization URL
auth_url, _ = flow.authorization_url(prompt='consent')
print(f"Go to this URL and authorize: {auth_url}")
print()
print("After authorization, you'll get a code. Paste it here:")
code = input("Enter the authorization code: ")

# Exchange code for credentials
flow.fetch_token(code=code)
credentials = flow.credentials

# Save credentials for Earth Engine
ee.Authenticate(auth_mode='gcloud', force=True)
print("Earth Engine authentication successful!")