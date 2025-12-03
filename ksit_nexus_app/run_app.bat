@echo off
echo Starting Flutter app...
echo.

echo Step 1: Cleaning project...
flutter clean

echo.
echo Step 2: Getting dependencies...
flutter pub get

echo.
echo Step 3: Running app...
flutter run -d chrome --web-port=8080

pause


