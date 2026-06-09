@echo off
title SpeakEasy — Install Dependencies
set "PATH=C:\Program Files\nodejs;%PATH%"
set "ROOT=%~dp0.."

echo Installing API...
cd /d "%ROOT%\api"
call npm ci
if errorlevel 1 call npm install

echo.
echo Installing Desktop...
cd /d "%ROOT%\desktop"
call npm install

echo.
echo Done.
pause