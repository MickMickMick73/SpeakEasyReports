@echo off
setlocal
title SpeakEasy - Codemagic automatic signing setup
set "KEY=%USERPROFILE%\Desktop\aapple api stuff\SpeakEasy_distribution_private_key.pem"
if not exist "%KEY%" set "KEY=C:\Users\a\Desktop\aapple api stuff\SpeakEasy_distribution_private_key.pem"

echo.
echo  Codemagic automatic signing (App Store Connect)
echo  =================================================
echo.
echo  The workflow now fetches cert + profile from Apple during each build.
echo  You only need ONE environment variable in Codemagic (one time):
echo.
echo  1. Open SpeakEasyReports app in Codemagic
echo  2. Environment variables ^> Add group: code-signing
echo  3. Add variable:
echo       Name:   CERTIFICATE_PRIVATE_KEY
echo       Value:  entire contents of the .pem file (including BEGIN/END lines)
echo       Secret: YES
echo  4. Confirm Team integration "SpeakEasy" is connected (Developer Portal)
echo.
if exist "%KEY%" (
  echo  Opening private key file for copy/paste...
  start "" notepad "%KEY%"
) else (
  echo  WARNING: %KEY% not found.
  echo  Run: python scripts\create_appstore_signing.py --force-new-cert
)
echo.
start "" "https://codemagic.io/apps"
pause