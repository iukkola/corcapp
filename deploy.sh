#!/bin/bash
# CORC App Deployment Script
# Deploys backend and Flutter web app to production server

set -e  # Exit on error

echo "🚀 Starting CORC app deployment..."

# Configuration
SERVER_HOST="co2"
SERVER_USER="root"
REMOTE_PATH="/root/hiilikrediitti-appi"
LOCAL_PATH="$(pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to print colored messages
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "CORC_MASTER_PLAN.md" ]; then
    print_error "Not in CORC project directory!"
    echo "Please run this script from the project root directory."
    exit 1
fi

# Step 1: Build Flutter app (if needed)
if [ "$1" == "--with-flutter" ]; then
    print_status "Building Flutter web app..."
    cd corc_flutter_app
    flutter build web --release
    cd ..
    print_status "Flutter web build complete"
fi

# Step 2: Sync backend files
print_status "Syncing backend files to production..."
rsync -avz --delete \
    --exclude 'venv' \
    --exclude '__pycache__' \
    --exclude '*.pyc' \
    --exclude '.env*' \
    --exclude '*.db' \
    --exclude '*.log' \
    backend/ ${SERVER_USER}@${SERVER_HOST}:${REMOTE_PATH}/backend/

# Step 3: Sync Flutter web build (if it exists)
if [ -d "corc_flutter_app/build/web" ]; then
    print_status "Syncing Flutter web build..."
    rsync -avz --delete \
        corc_flutter_app/build/web/ \
        ${SERVER_USER}@${SERVER_HOST}:${REMOTE_PATH}/corc_flutter_app/build/web/
fi

# Step 4: Copy production environment file
print_status "Updating production environment configuration..."
scp backend/.env.production ${SERVER_USER}@${SERVER_HOST}:${REMOTE_PATH}/backend/.env

# Step 5: Restart services on server
print_status "Restarting backend service..."
ssh ${SERVER_USER}@${SERVER_HOST} << 'EOF'
    cd /root/hiilikrediitti-appi/backend
    
    # Kill existing backend process
    pkill -f "uvicorn main:app" || true
    
    # Activate virtual environment and install dependencies
    source venv/bin/activate
    pip install -r requirements.txt
    
    # Start backend with nohup
    nohup uvicorn main:app --host 0.0.0.0 --port 8000 > server.log 2>&1 &
    
    # Wait a moment and check if it started
    sleep 3
    if pgrep -f "uvicorn main:app" > /dev/null; then
        echo "✓ Backend restarted successfully"
    else
        echo "✗ Backend failed to start - check server.log"
        exit 1
    fi
    
    # Restart web server for Flutter app if needed
    if [ -d "/root/hiilikrediitti-appi/corc_flutter_app/build/web" ]; then
        pkill -f "python3 -m http.server 8080" || true
        cd /root/hiilikrediitti-appi/corc_flutter_app/build/web
        nohup python3 -m http.server 8080 > /dev/null 2>&1 &
        echo "✓ Flutter web server restarted"
    fi
EOF

print_status "Deployment complete! 🎉"
echo ""
echo "Services running:"
echo "  - Backend API: http://91.99.150.88:8000"
echo "  - Flutter Web: http://91.99.150.88:8080"
echo ""
echo "Mobile app users will continue using the API at port 8000"