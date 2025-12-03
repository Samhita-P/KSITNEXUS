@echo off
echo ========================================
echo Adding Firewall Rule for Django Server
echo ========================================
echo.
echo This will allow incoming connections on port 8002
echo.
echo NOTE: This requires Administrator privileges!
echo.
pause

echo.
echo Adding firewall rule...
netsh advfirewall firewall add rule name="Django Development Server" dir=in action=allow protocol=TCP localport=8002

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Firewall rule added successfully!
    echo.
    echo Port 8002 is now open for incoming connections.
) else (
    echo.
    echo ❌ Failed to add firewall rule.
    echo.
    echo Please run this script as Administrator:
    echo 1. Right-click this file
    echo 2. Select "Run as administrator"
    echo.
)

echo.
pause

