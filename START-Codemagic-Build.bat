@echo off
title SpeakEasy - Start Codemagic iOS Build
echo.
echo  Before building, confirm in Codemagic Team settings:
echo    speakeasy-dist certificate + speakeasy-appstore-profile
echo    for com.speakeasy.speakeasyReports with GREEN checkmark under Certificate.
echo    Run SETUP-Codemagic-Signing.bat if missing.
echo.
echo  Opening SpeakEasyReports in Codemagic...
start "" "https://codemagic.io/apps"
pause