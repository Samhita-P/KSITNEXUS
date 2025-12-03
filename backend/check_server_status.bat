@echo off
echo ========================================
echo Checking Django Server Status
echo ========================================
echo.

echo Checking if server is listening on port 8002...
netstat -an | findstr :8002

echo.
echo ========================================
echo Interpretation:
echo ========================================
echo.
echo If you see: TCP    0.0.0.0:8002
echo   ✅ Server is accessible from mobile devices
echo.
echo If you see: TCP    127.0.0.1:8002
echo   ❌ Server is ONLY accessible from this computer
echo   → You need to restart with: python manage.py runserver 0.0.0.0:8002
echo.
echo If you see nothing:
echo   ❌ Server is not running
echo   → Start it with: python manage.py runserver 0.0.0.0:8002
echo.
echo ========================================
echo Your IP Address:
echo ========================================
ipconfig | findstr /i "IPv4"

pause

