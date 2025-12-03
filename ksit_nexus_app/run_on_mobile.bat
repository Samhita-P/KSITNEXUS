@echo off
echo ========================================
echo KSIT Nexus - Mobile Device Runner
echo ========================================
echo.

cd /d "%~dp0"

echo Checking for connected devices...
flutter devices
echo.

echo If your mobile device is listed above, the app will launch automatically.
echo If not, please:
echo   1. Connect your phone via USB
echo   2. Enable USB Debugging in Developer Options
echo   3. Run this script again
echo.

pause

echo.
echo Launching app on connected device...
flutter run

pause

