@echo off
title Push SpeakEasyReports to GitHub
cd /d "%~dp0"

echo.
echo  Push SpeakEasyReports to GitHub for Codemagic
echo  ==============================================
echo.
echo  1. Create repo at https://github.com/new  (name: SpeakEasyReports, Private)
echo  2. Do NOT add README or gitignore on GitHub
echo  3. Copy the repo URL GitHub shows, then paste it below.
echo.
set /p REPO_URL=GitHub repo URL (https://github.com/USER/SpeakEasyReports.git): 

if "%REPO_URL%"=="" (
  echo No URL entered.
  pause
  exit /b 1
)

git remote remove origin 2>nul
git remote add origin "%REPO_URL%"
git push -u origin main

if errorlevel 1 (
  echo.
  echo Push failed. Check GitHub login and repo URL.
  pause
  exit /b 1
)

echo.
echo Done. Open https://codemagic.io/apps and add SpeakEasyReports.
echo Full guide: docs\CODEMAGIC-NEXT-STEPS.md
pause