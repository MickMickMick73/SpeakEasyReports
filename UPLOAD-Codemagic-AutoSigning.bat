@echo off
setlocal
title SpeakEasy - Upload signing to Codemagic (API)
set "ROOT=%~dp0"
set "TOKEN=%USERPROFILE%\Desktop\aapple api stuff\codemagic-api-token.txt"
if not exist "%TOKEN%" set "TOKEN=C:\Users\a\Desktop\aapple api stuff\codemagic-api-token.txt"

echo.
echo  Upload CERTIFICATE_PRIVATE_KEY to Codemagic (automatic signing)
echo  ================================================================
echo.

if not exist "%TOKEN%" (
  echo  Missing Codemagic API token file:
  echo    %TOKEN%
  echo.
  echo  1. Open Codemagic ^> Teams ^> Personal Account ^> Integrations ^> Codemagic API ^> Show
  echo  2. Copy the token into a new file at the path above (one line, no spaces)
  echo  3. Run this script again
  echo.
  start "" "https://codemagic.io/teams/6a277febc3867daed2847fcf"
  pause
  exit /b 1
)

python "%ROOT%scripts\upload_codemagic_signing.py" --trigger-build
set "RC=%ERRORLEVEL%"
echo.
if "%RC%"=="0" (
  echo  Done. Codemagic will build speakeasy-ios on main and submit to TestFlight.
) else (
  echo  Upload failed. Check the error above.
)
pause
exit /b %RC%