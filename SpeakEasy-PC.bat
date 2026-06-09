@echo off
setlocal
title SpeakEasy Reports - PC
set "PATH=C:\Program Files\nodejs;%PATH%"
set "ROOT=%~dp0"

echo.
echo  SpeakEasy Reports - Desktop + Server
echo  ====================================
echo.

cd /d "%ROOT%api"
if not exist node_modules (
  echo  Installing API dependencies...
  call npm ci
  if errorlevel 1 call npm install
  if errorlevel 1 (
    echo.
    echo  ERROR: Could not install API dependencies.
    pause
    exit /b 1
  )
)

cd /d "%ROOT%desktop"
if not exist node_modules (
  echo  Installing Desktop app dependencies...
  call npm install
  if errorlevel 1 (
    echo.
    echo  ERROR: Could not install Desktop dependencies.
    pause
    exit /b 1
  )
)

if not exist "%ROOT%desktop\node_modules\electron\dist\electron.exe" (
  echo  Repairing Electron desktop runtime...
  powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%scripts\repair-electron.ps1"
  if errorlevel 1 (
    echo.
    echo  ERROR: Could not repair Electron. Try running scripts\repair-electron.ps1 manually.
    pause
    exit /b 1
  )
)

echo  Starting SpeakEasy Desktop...
echo  Keep this window open while using the app.
echo.

start "SpeakEasy Desktop" /D "%ROOT%desktop" cmd /c "npm start"

timeout /t 3 /nobreak >nul
echo  Desktop launched. Use the app window to connect your phone.
echo  API URL will show inside the desktop app.
echo.
pause