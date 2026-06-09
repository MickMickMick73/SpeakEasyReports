@echo off
setlocal
title SpeakEasy Reports - iPhone Build
set "ROOT=%~dp0"

echo.
echo  SpeakEasy Reports - iPhone (iOS) build
echo  ======================================
echo.
echo  Windows cannot build iPhone apps directly.
echo  We use Codemagic (free cloud Mac) to build the IPA, then install on your iPhone.
echo.
echo  WHAT IS READY:
echo    - Flutter app: mobile\
echo    - iOS permissions + LAN sync: mobile\ios\
echo    - Cloud build config: codemagic.yaml
echo    - PC Link bridge: SpeakEasy-Link.bat  (already working on your phone)
echo.
echo  STEPS:
echo    1. Run PREPARE-iPhone-Build.bat  (git + GitHub)
echo    2. Sign up at https://codemagic.io  (free tier)
echo    3. Connect your GitHub repo
echo    4. Add Apple ID / code signing in Codemagic settings
echo    5. Start build - speakeasy-ios workflow
echo    6. Download IPA from Codemagic
echo    7. Install on iPhone (see docs\BUILD-iPHONE.md)
echo.
echo  Full guide: %ROOT%docs\BUILD-iPHONE.md
echo.
start "" "%ROOT%docs\BUILD-iPHONE.md"
pause