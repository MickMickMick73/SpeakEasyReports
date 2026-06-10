@echo off
setlocal
title SpeakEasy - Codemagic automatic signing setup
set "KEY=%USERPROFILE%\Desktop\aapple api stuff\SpeakEasy_distribution_private_key.pem"
if not exist "%KEY%" set "KEY=C:\Users\a\Desktop\aapple api stuff\SpeakEasy_distribution_private_key.pem"

echo.
echo  Codemagic automatic signing (App Store Connect)
echo  =================================================
echo.
echo  Automatic path (recommended):
echo    1. Save Codemagic API token to:
echo       %USERPROFILE%\Desktop\aapple api stuff\codemagic-api-token.txt
echo       (Teams ^> Personal Account ^> Integrations ^> Codemagic API ^> Show)
echo    2. Double-click UPLOAD-Codemagic-AutoSigning.bat
echo.
echo  Manual path (if API upload is unavailable):
echo    1. Open SpeakEasyReports app in Codemagic
echo    2. Environment variables ^> Add group: code-signing
echo    3. Add secret variable CERTIFICATE_PRIVATE_KEY = full .pem file contents
echo    4. Confirm Team integration "SpeakEasy" is connected (Developer Portal)
echo.
if not exist "%KEY%" (
  echo  WARNING: %KEY% not found.
  echo  Run: python scripts\create_appstore_signing.py --force-new-cert
)
echo.
start "" "https://codemagic.io/teams/6a277febc3867daed2847fcf"
pause