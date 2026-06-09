@echo off
setlocal
title SpeakEasy Link
set "PATH=C:\Program Files\nodejs;%PATH%"
set "ROOT=%~dp0"

echo.
echo  SpeakEasy Link - standalone phone to PC bridge
echo  ==============================================
echo.
echo  No inspection flow required. Test connection, push files, edit shared notes.
echo.

cd /d "%ROOT%api"
if not exist node_modules (
  echo  Installing API dependencies...
  call npm ci
  if errorlevel 1 call npm install
)

cd /d "%ROOT%desktop"
if not exist node_modules (
  echo  Installing Desktop dependencies...
  call npm install
)

if not exist "%ROOT%desktop\node_modules\electron\dist\electron.exe" (
  echo  Repairing Electron...
  powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%scripts\repair-electron.ps1"
)

for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
  for /f "tokens=1" %%b in ("%%a") do set "LAN_IP=%%b"
)

echo  Phone app (Safari): http://%LAN_IP%:3001/link
echo  Shared folder: %ROOT%link-share
echo.

start "SpeakEasy Desktop" /D "%ROOT%desktop" cmd /c "npm start"
timeout /t 3 /nobreak >nul
start "" "http://%LAN_IP%:3001/link"

echo  Desktop + phone link page launched.
echo  On iPhone: open the link URL or scan QR from desktop Connect tab.
echo.
pause