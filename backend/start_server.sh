#!/bin/bash

# Start Django server on all network interfaces
# Run this script on the remote server

cd "$(dirname "$0")"

# Activate virtual environment
if [ -d "../venv" ]; then
    source ../venv/bin/activate
else
    echo "Error: Virtual environment not found. Please run deploy.sh first."
    exit 1
fi

# Start server
echo "Starting Django server on 0.0.0.0:8002..."
echo "Server will be accessible at:"
echo "  - http://100.87.200.4:8002"
echo "  - http://100.87.200.4:8002/api"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

python manage.py runserver 0.0.0.0:8002

