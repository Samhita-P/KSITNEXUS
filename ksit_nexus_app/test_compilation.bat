@echo off
echo Testing Flutter compilation...
echo.

echo Step 1: Cleaning project...
flutter clean
if %errorlevel% neq 0 (
    echo Error: flutter clean failed
    pause
    exit /b 1
)

echo.
echo Step 2: Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo Error: flutter pub get failed
    pause
    exit /b 1
)

echo.
echo Step 3: Running code generation...
flutter packages pub run build_runner build --delete-conflicting-outputs
if %errorlevel% neq 0 (
    echo Warning: build_runner failed, but continuing...
)

echo.
echo Step 4: Testing compilation...
flutter build web --no-sound-null-safety
if %errorlevel% neq 0 (
    echo Error: Flutter build failed
    pause
    exit /b 1
)

echo.
echo SUCCESS! Flutter app compiles successfully.
echo You can now run: flutter run -d chrome
pause


