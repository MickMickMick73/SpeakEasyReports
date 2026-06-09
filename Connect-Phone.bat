@echo off
setlocal
title LAN Connect Hub
set "PATH=C:\Program Files\nodejs;%PATH%"
set "ROOT=%~dp0"

echo.
echo  LAN Connect Hub - universal phone to PC sync setup
echo  ==================================================
echo.
echo  This tool is for REPORT SYNC only (not app version installs).
echo.

cd /d "%ROOT%api"
if not exist node_modules (
  echo  Installing API dependencies...
  call npm ci
  if errorlevel 1 call npm install
)

for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
  for /f "tokens=1" %%b in ("%%a") do set "LAN_IP=%%b"
)

echo  PC LAN IP: %LAN_IP%
echo  Connect page: http://%LAN_IP%:3001/connect
echo  API URL for apps: http://%LAN_IP%:3001
echo.
echo  Starting server if not already running...
echo.

netstat -ano | findstr ":3001" | findstr "LISTENING" >nul
if errorlevel 1 (
  echo  Server not detected - start SpeakEasy-PC.bat first, or starting API only...
  start "SpeakEasy API" /D "%ROOT%api" cmd /k "npm start"
  timeout /t 3 /nobreak >nul
)

start "" "http://%LAN_IP%:3001/connect"
echo  Opened connect page in your browser.
echo  On iPhone: scan QR from SpeakEasy desktop OR open the same /connect URL.
echo.
pause