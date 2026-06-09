@echo off
setlocal
title SpeakEasy - Fix Codemagic signing (5 min)
set "BUNDLE=com.speakeasy.speakeasyReports"

echo.
echo  FIX: No matching ad_hoc profile for %BUNDLE%
echo  =================================================
echo.
echo  EAS has signing on Expo servers. Codemagic needs its OWN copy.
echo  Do these 3 steps in order (browser tabs will open):
echo.
echo  STEP 1 - Create App ID (skip if it already exists in the list)
echo    developer.apple.com - Identifiers - + - App IDs
echo    Bundle ID: %BUNDLE%
echo.
echo  STEP 2 - Create Ad Hoc profile
echo    developer.apple.com - Profiles - + - Ad Hoc
echo    App ID: %BUNDLE%
echo    Certificate: Apple Distribution (your dist cert)
echo    Devices: tick your iPhone
echo    Name: SpeakEasy AdHoc
echo.
echo  STEP 3 - Load profile into Codemagic
echo    Team settings - codemagic.yaml settings - Code signing identities
echo    iOS provisioning profiles - Fetch profiles
echo    Ad Hoc: pick %BUNDLE% - reference speakeasy-adhoc - Download selected
echo    (Ignore com.varm.assessment and com.varm.ultimauhr)
echo.
echo  STEP 4 - Re-run build
echo    SpeakEasyReports - SpeakEasy Reports iOS - main - Start new build
echo.
start "" "https://developer.apple.com/account/resources/identifiers/list"
start "" "https://developer.apple.com/account/resources/profiles/list"
start "" "https://codemagic.io/teams/6a277febc3867daed2847fcf"
timeout /t 2 >nul
start "" "https://codemagic.io/apps"
pause