@echo off
setlocal
title SpeakEasy Reports - iPhone Build
set "ROOT=%~dp0"

echo.
echo  SpeakEasy Reports - iPhone (iOS) build
echo  ======================================
echo.
echo  Windows cannot build iPhone apps directly.
echo  EAS Build (Expo cloud) — same easy path as InspectPro. One double-click.
echo.
echo  WHAT IS READY:
echo    - Flutter app: mobile\
echo    - EAS config: mobile\eas.json + mobile\.eas\build\flutter-ios.yml
echo    - PC Link bridge: SpeakEasy-Link.bat  (already working on your phone)
echo.
echo  STEPS:
echo    1. Double-click BUILD-iPhone-EAS.bat
echo    2. Wait for build (~15-25 min)
echo    3. Open install link on iPhone (Safari)
echo.
echo  Codemagic is optional backup only (docs\CODEMAGIC-NEXT-STEPS.md).
echo.
echo  Run: BUILD-iPhone-EAS.bat
echo  Guide: docs\BUILD-iPHONE-EAS.md
echo.
start "" "%ROOT%BUILD-iPhone-EAS.bat"
pause