@echo off
echo Cleaning Flutter project...
flutter clean

echo Getting dependencies...
flutter pub get

echo Running code generation...
flutter packages pub run build_runner build --delete-conflicting-outputs

echo Done! You can now run: flutter run
pause


