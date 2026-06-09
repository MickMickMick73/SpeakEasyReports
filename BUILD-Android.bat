@echo off
setlocal
cd /d "%~dp0"

set FLUTTER=%~dp0tools\flutter\bin\flutter.bat
if not exist "%FLUTTER%" (
  echo Flutter SDK not found at tools\flutter
  echo Install Flutter or run: git clone https://github.com/flutter/flutter.git -b stable tools\flutter
  pause
  exit /b 1
)

echo.
echo === SpeakEasy Reports — Android APK build (free, no FlutterFlow token) ===
echo.

cd mobile
call "%FLUTTER%" pub get
if errorlevel 1 goto :fail

call "%FLUTTER%" analyze
if errorlevel 1 goto :fail

call "%FLUTTER%" build apk --release
if errorlevel 1 goto :fail

echo.
echo === Build complete ===
echo APK: mobile\build\app\outputs\flutter-apk\app-release.apk
echo.
echo Install: copy APK to phone, or connect USB and run:
echo   tools\flutter\bin\flutter.bat install --release
echo.
pause
exit /b 0

:fail
echo.
echo Build failed. See errors above.
pause
exit /b 1