#!/bin/bash

# Automated Deployment Script for KSIT Nexus Backend
# This script transfers the project and sets up the backend on the remote server

set -e  # Exit on error

SERVER_USER="mvpi_backend"
SERVER_IP="100.87.200.4"
SERVER_PATH="~/ksit_nexus"
PROJECT_NAME="KSIT NEXUS - Copy"

echo "========================================="
echo "KSIT Nexus - Automated Server Deployment"
echo "========================================="
echo ""

# Step 1: Transfer project to server
echo "[1/9] Transferring project to server..."
echo "This may take several minutes..."
scp -r "$PROJECT_NAME" ${SERVER_USER}@${SERVER_IP}:${SERVER_PATH}/

if [ $? -eq 0 ]; then
    echo "✅ Project transferred successfully"
else
    echo "❌ Transfer failed. Please check SSH connection and try again."
    exit 1
fi

echo ""

# Step 2: SSH and set up backend
echo "[2/9] Connecting to server and setting up backend..."
ssh ${SERVER_USER}@${SERVER_IP} << 'ENDSSH'
    set -e
    
    echo "Connected to server. Setting up backend..."
    
    # Navigate to project
    cd ~/ksit_nexus
    if [ -d "KSIT NEXUS - Copy" ]; then
        cd "KSIT NEXUS - Copy"
    fi
    cd backend
    
    # Step 3: Create virtual environment
    echo "[3/9] Creating virtual environment..."
    if [ ! -d "../venv" ]; then
        python3 -m venv ../venv
        echo "✅ Virtual environment created"
    else
        echo "✅ Virtual environment already exists"
    fi
    
    # Step 4: Activate and install dependencies
    echo "[4/9] Activating virtual environment and installing dependencies..."
    source ../venv/bin/activate
    pip install --upgrade pip
    pip install -r requirements.txt
    echo "✅ Dependencies installed"
    
    # Step 5: Create .env file
    echo "[5/9] Creating .env file..."
    if [ ! -f ".env" ]; then
        cp env.example .env
        echo "✅ .env file created from template"
        echo "⚠️  Note: Please update SECRET_KEY in .env file for production"
    else
        echo "✅ .env file already exists"
    fi
    
    # Step 6: Run migrations
    echo "[6/9] Running database migrations..."
    python manage.py migrate
    echo "✅ Migrations completed"
    
    # Step 7: Collect static files
    echo "[7/9] Collecting static files..."
    python manage.py collectstatic --noinput
    echo "✅ Static files collected"
    
    echo ""
    echo "========================================="
    echo "Backend setup completed successfully!"
    echo "========================================="
    echo ""
    echo "To start the server, run:"
    echo "  cd ~/ksit_nexus/backend"
    echo "  source ../venv/bin/activate"
    echo "  python manage.py runserver 0.0.0.0:8002"
    echo ""
    echo "Or use the start script:"
    echo "  ./start_server.sh"
    echo ""
ENDSSH

if [ $? -eq 0 ]; then
    echo "✅ Server setup completed successfully"
else
    echo "❌ Server setup failed"
    exit 1
fi

echo ""
echo "========================================="
echo "Deployment Summary"
echo "========================================="
echo "✅ Project transferred to server"
echo "✅ Virtual environment created"
echo "✅ Dependencies installed"
echo "✅ Database migrations run"
echo "✅ Static files collected"
echo ""
echo "Next steps:"
echo "1. SSH to server: ssh ${SERVER_USER}@${SERVER_IP}"
echo "2. Start server: cd ~/ksit_nexus/backend && source ../venv/bin/activate && python manage.py runserver 0.0.0.0:8002"
echo ""

