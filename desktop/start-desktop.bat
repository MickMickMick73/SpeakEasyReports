@echo off
setlocal
set "PATH=C:\Program Files\nodejs;%PATH%"
cd /d "%~dp0"

echo Starting SpeakEasy Desktop...
npm start
if errorlevel 1 (
  echo.
  echo Desktop failed to start. See errors above.
  pause
  exit /b 1
)