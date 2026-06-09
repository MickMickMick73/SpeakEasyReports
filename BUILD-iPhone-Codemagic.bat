@echo off
setlocal
title SpeakEasy - Codemagic iOS Build
set "ROOT=%~dp0"

echo.
echo  SpeakEasy iOS build via Codemagic (use while EAS credits are out)
echo  =================================================================
echo.
echo  EAS signing is DONE. Expo free iOS builds reset on 1 Jul 2026.
echo  Codemagic still has free build minutes this month.
echo.
echo  Build failed? Run SETUP-Codemagic-Signing.bat first (5 min one-time).
echo  Guide: docs\FIX-CODEMAGIC-PROFILE.md
echo.
echo  THEN start build:
echo    https://codemagic.io/apps
echo    SpeakEasyReports - workflow SpeakEasy Reports iOS - branch main
echo.
start "" "https://codemagic.io/apps"
start "" "%ROOT%docs\CODEMAGIC-NEXT-STEPS.md"
pause