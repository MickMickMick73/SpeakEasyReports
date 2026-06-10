@echo off
setlocal
title SpeakEasy - Create TestFlight signing (App Store)
set "BUNDLE=com.speakeasy.speakeasyReports"
set "TEAM=H9PMCU8928"

echo.
echo  SpeakEasy TestFlight signing setup
echo  ==================================
echo.
echo  Bundle ID (all platforms): %BUNDLE%
echo  Apple Team ID:             %TEAM%
echo.
echo  Your existing SpeakEasy_Dev profile is DEVELOPMENT only.
echo  TestFlight needs APP STORE signing with these exact Codemagic names:
echo    Certificate reference: speakeasy-dist
echo    Profile reference:   speakeasy-appstore-profile
echo.
echo  STEP 1 - Codemagic: Apple Distribution certificate
echo  ---------------------------------------------------
echo  Team settings ^> Code signing identities ^> iOS certificates
echo  Click Generate certificate
echo    Type:      Apple Distribution
echo    Reference: speakeasy-dist
echo    API key:   SpeakEasy
echo  If Generate fails (3 cert limit), click Fetch certificate instead.
echo.
echo  STEP 2 - Apple Developer: App ID (skip if exists)
echo  --------------------------------------------------
echo  Identifiers ^> confirm %BUNDLE% exists under team %TEAM%
echo.
echo  STEP 3 - Apple Developer: App Store profile
echo  --------------------------------------------
echo  Profiles ^> + ^> App Store (Distribution)
echo    App ID:  %BUNDLE%
echo    Cert:    Apple Distribution (speakeasy-dist)
echo    Name:    SpeakEasy App Store
echo  No device list needed for App Store profiles.
echo.
echo  STEP 4 - Codemagic: fetch App Store profile
echo  --------------------------------------------
echo  iOS provisioning profiles ^> Fetch profiles
echo  Open: App Store profiles (NOT Development / NOT Ad Hoc)
echo  Select: %BUNDLE%
echo  Reference: speakeasy-appstore-profile
echo  Download selected
echo  GREEN checkmark under Certificate = ready
echo.
echo  STEP 5 - App Store Connect: app record (first time only)
echo  ---------------------------------------------------------
echo  Apps ^> + ^> New App ^> bundle %BUNDLE%
echo.
echo  STEP 6 - Rebuild
echo  ----------------
echo  Codemagic ^> SpeakEasy Reports iOS ^> main ^> Start new build
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\verify-ios-bundle-id.ps1"
echo.
start "" "https://codemagic.io/teams/6a277febc3867daed2847fcf"
timeout /t 1 >nul
start "" "https://developer.apple.com/account/resources/identifiers/list"
timeout /t 1 >nul
start "" "https://developer.apple.com/account/resources/profiles/add"
timeout /t 1 >nul
start "" "https://appstoreconnect.apple.com/apps"
timeout /t 1 >nul
start "" "https://codemagic.io/apps"
pause