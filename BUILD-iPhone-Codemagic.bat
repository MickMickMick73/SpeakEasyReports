@echo off
setlocal
title SpeakEasy - Codemagic iOS Build
set "ROOT=%~dp0"

echo.
echo  SpeakEasy iOS build via Codemagic (use while EAS credits are out)
echo  =================================================================
echo.
echo  EAS signing is DONE. Expo free iOS builds reset on 1 Jul 2026.
echo  Codemagic still has free build minutes this month.
echo.
echo  ONE-TIME in Codemagic (if not done yet):
echo    Team settings - codemagic.yaml settings - Code signing identities
echo    1. Generate Apple Distribution certificate (speakeasy-dist)
echo    2. Create App ID com.speakeasy.speakeasyReports on developer.apple.com
echo    3. Create Ad Hoc profile for that bundle ID
echo    4. Fetch profile in Codemagic - Download selected
echo.
echo  THEN start build:
echo    https://codemagic.io/apps
echo    SpeakEasyReports - workflow SpeakEasy Reports iOS - branch main
echo.
start "" "https://codemagic.io/apps"
start "" "%ROOT%docs\CODEMAGIC-NEXT-STEPS.md"
pause