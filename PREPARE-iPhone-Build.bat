@echo off
setlocal
title Prepare iPhone Build
set "ROOT=%~dp0"
cd /d "%ROOT%"

echo.
echo  Prepare SpeakEasy Reports for iPhone cloud build
echo  =================================================
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo  Git is not installed. Install from https://git-scm.com/download/win
  pause
  exit /b 1
)

if not exist .git (
  echo  Initializing git repository...
  git init
  git branch -M main
)

git add -A
git status

echo.
echo  Next — create GitHub repo and push:
echo.
echo    1. https://github.com/new  - name: SpeakEasyReports  - Private
echo    2. Then run (replace YOUR_USER):
echo.
echo       git remote add origin https://github.com/YOUR_USER/SpeakEasyReports.git
echo       git commit -m "SpeakEasy Reports iOS build"
echo       git push -u origin main
echo.
echo    3. Open https://codemagic.io and connect the repo
echo    4. Run BUILD-iPhone.bat workflow or start speakeasy-ios in Codemagic
echo.
pause