#!/bin/bash
echo "========================================"
echo "Starting Django Server for Mobile Access"
echo "========================================"
echo ""
echo "Server will be accessible at:"
echo "  - http://10.222.10.6:8002 (from mobile devices)"
echo "  - http://localhost:8002 (from this computer)"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""

cd "$(dirname "$0")"
python manage.py runserver 0.0.0.0:8002

