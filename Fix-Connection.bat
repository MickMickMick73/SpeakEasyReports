@echo off
title SpeakEasy - Fix Connection
echo.
echo  SpeakEasy Connection Fix
echo  ========================
echo.
echo  Adds Windows firewall rules so your iPhone can reach this PC on port 3001.
echo  RIGHT-CLICK this file and choose "Run as administrator" if it fails.
echo.

netsh advfirewall firewall add rule name="SpeakEasy API 3001" dir=in action=allow protocol=TCP localport=3001

if %ERRORLEVEL% NEQ 0 (
  echo.
  echo  FAILED - run this file as Administrator.
  pause
  exit /b 1
)

echo.
echo  Firewall rule added for port 3001.
echo.
echo  Your PC API URL for the phone:
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
  for /f "tokens=1" %%b in ("%%a") do echo    http://%%b:3001
)
echo.
echo  Next steps:
echo    1. Keep SpeakEasy-PC.bat running
echo    2. iPhone on same home Wi-Fi (not guest network, not mobile data)
echo    3. InspectPro Settings - API base URL - paste URL above
echo    4. Tap Test API connection
echo.
pause