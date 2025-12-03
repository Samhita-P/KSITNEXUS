#!/bin/bash

# KSIT Nexus Backend Deployment Script
# Run this script on the remote server after copying the project

set -e  # Exit on error

echo "========================================="
echo "KSIT Nexus Backend Deployment"
echo "========================================="

# Check if we're in the right directory
if [ ! -f "manage.py" ]; then
    echo "Error: manage.py not found. Please run this script from the backend directory."
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "../venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv ../venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source ../venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Create .env file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "Creating .env file from template..."
    cp env.example .env
    echo ""
    echo "⚠️  IMPORTANT: Please edit .env file and set your SECRET_KEY and other settings!"
    echo "   Run: nano .env"
    read -p "Press Enter after editing .env file..."
fi

# Run migrations
echo "Running database migrations..."
python manage.py migrate

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

echo ""
echo "========================================="
echo "Deployment completed successfully!"
echo "========================================="
echo ""
echo "To start the server, run:"
echo "  source ../venv/bin/activate"
echo "  python manage.py runserver 0.0.0.0:8002"
echo ""
echo "Server will be accessible at:"
echo "  http://100.87.200.4:8002"
echo "  http://100.87.200.4:8002/api"
echo ""

