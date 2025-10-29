@echo off
echo ====================================
echo Running Flutter App on Physical iPhone
echo ====================================
echo.
echo PREREQUISITES:
echo 1. iPhone connected via USB cable
echo 2. Xcode installed on Mac (if using Mac)
echo 3. iPhone in Developer Mode
echo 4. Trusted this computer on iPhone
echo.
echo ====================================
echo.

cd /d "%~dp0"

echo Detecting connected iOS devices...
flutter devices

echo.
echo ====================================
echo Select your iPhone from the list above
echo Then run: flutter run -d [device-id]
echo ====================================
echo.
echo Example: flutter run -d 00008030-001234567890401E
echo.
echo Starting Flutter in iOS mode...
echo.

flutter run

pause
