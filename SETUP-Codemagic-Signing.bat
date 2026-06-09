@echo off
setlocal
title SpeakEasy - Fix Codemagic signing
set "BUNDLE=com.speakeasy.speakeasyReports"

echo.
echo  SpeakEasy Codemagic signing - EASIER path (Development, not Ad Hoc)
echo  ====================================================================
echo.
echo  Your iPhone IS registered: UDID 00008150-001A58110CF1401C
echo.
echo  DO THIS ORDER (Codemagic FIRST, then Apple):
echo.
echo  [A] CODMAGIC - create certificate (2 min)
echo      Team settings - Code signing identities - iOS certificates
echo      Generate certificate
echo        Type: Apple DEVELOPMENT  (not Distribution - easier)
echo        Reference: speakeasy-dev
echo        API key: your integrated key
echo      Create - upload back if asked
echo.
echo  [B] APPLE - App ID (if missing)
echo      Identifiers - + - App ID - %BUNDLE%
echo.
echo  [C] APPLE - Development profile (NOT Ad Hoc)
echo      Profiles - + - iOS App DEVELOPMENT
echo        App: %BUNDLE%
echo        Cert: Apple DEVELOPMENT (the one from step A or iPhone Developer)
echo        Devices: TICK THE CHECKBOX next to your iPhone  (required!)
echo        Name: SpeakEasy Dev
echo      Generate / Save
echo.
echo  STUCK on Generate? Usually one of these:
echo    - No certificate ticked
echo    - No device checkbox ticked (most common)
echo    - Wrong profile type (use Development not Ad Hoc)
echo    - App ID %BUNDLE% does not exist yet
echo.
echo  [D] CODMAGIC - fetch profile
echo      iOS provisioning profiles - Fetch profiles
echo      Development profiles - %BUNDLE% - speakeasy-dev-profile - Download
echo.
echo  [E] Rebuild SpeakEasy Reports iOS on main
echo.
start "" "https://codemagic.io/teams/6a277febc3867daed2847fcf"
timeout /t 1 >nul
start "" "https://developer.apple.com/account/resources/identifiers/list"
timeout /t 1 >nul
start "" "https://developer.apple.com/account/resources/profiles/add"
timeout /t 1 >nul
start "" "https://developer.apple.com/account/resources/devices/list"
timeout /t 1 >nul
start "" "https://codemagic.io/apps"
pause