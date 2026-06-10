@echo off
setlocal
title SpeakEasy - Codemagic TestFlight signing
set "BUNDLE=com.speakeasy.speakeasyReports"

echo.
echo  SpeakEasy Codemagic signing - TestFlight (App Store)
echo  =====================================================
echo.
echo  Your workflow needs APP STORE signing (not Development).
echo  Reference names must match codemagic.yaml exactly:
echo    Certificate: speakeasy-dist
echo    Profile:     speakeasy-appstore-profile
echo.
echo  DO THIS ORDER:
echo.
echo  [A] CODMAGIC - Distribution certificate
echo      Team settings - Code signing identities - iOS certificates
echo      Generate certificate (or Fetch if you already have one)
echo        Type: Apple DISTRIBUTION
echo        Reference: speakeasy-dist
echo        API key: SpeakEasy (your integrated key)
echo.
echo  [B] APPLE - App ID (if missing)
echo      Identifiers - + - App ID - %BUNDLE%
echo.
echo  [C] APPLE - App Store profile
echo      Profiles - + - App Store (under Distribution)
echo        App: %BUNDLE%
echo        Cert: Apple Distribution (from step A)
echo        Name: SpeakEasy App Store
echo      Generate / Save
echo      (No device checkbox needed for App Store)
echo.
echo  [D] CODMAGIC - fetch App Store profile
echo      iOS provisioning profiles - Fetch profiles
echo      App Store profiles - %BUNDLE%
echo        Reference: speakeasy-appstore-profile
echo      Download selected
echo      GREEN checkmark under Certificate = ready
echo.
echo  [E] APP STORE CONNECT - app record (first time only)
echo      Apps - + - New App - bundle %BUNDLE%
echo.
echo  [F] Rebuild SpeakEasy Reports iOS on main
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