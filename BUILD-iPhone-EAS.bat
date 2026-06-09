@echo off
setlocal
title SpeakEasy Reports - iPhone Build (EAS)
set "ROOT=%~dp0"
set "MOBILE=%ROOT%mobile"

echo.
echo  SpeakEasy Reports - iPhone build via EAS (same as InspectPro)
echo  ==============================================================
echo.
echo  Expo handles Apple signing on their servers - no Codemagic clicking.
echo  Account: mikeykool401 (already logged in on this PC)
echo.

cd /d "%MOBILE%"
if errorlevel 1 (
  echo ERROR: mobile folder not found.
  pause
  exit /b 1
)

echo [1/2] Linking EAS project (once)...
call npx eas-cli init --non-interactive --force
if errorlevel 1 (
  echo EAS init failed.
  pause
  exit /b 1
)

echo.
echo [2/2] Starting cloud iOS build (preview / internal)...
echo       First time may ask ONE Apple signing question - pick defaults.
echo       Install link appears when build finishes (~15-25 min).
echo.
call npx eas-cli build --platform ios --profile preview
set "RC=%ERRORLEVEL%"

echo.
if "%RC%"=="0" (
  echo Done. Open the install link on your iPhone in Safari.
) else (
  echo Build failed or cancelled. Check the log URL above.
)
pause
exit /b %RC%