@echo off
setlocal
title SpeakEasy - Upload signing files to Codemagic
set "DIR=C:\Users\a\Desktop\aapple api stuff"

echo.
echo  Upload these files to Codemagic Code signing identities:
echo.
echo  1) iOS certificates tab ^> Upload
echo     File: %DIR%\SpeakEasy_Distribution.p12
echo     Reference name: speakeasy-dist
echo     Password: (see SpeakEasy_AppStore_signing.json in same folder)
echo.
echo  2) iOS provisioning profiles tab ^> Upload
echo     File: %DIR%\SpeakEasy_AppStore.mobileprovision
echo     Reference name: speakeasy-appstore-profile
echo.
echo  Then rebuild SpeakEasy Reports iOS on main.
echo.
start "" "https://codemagic.io/teams/6a277febc3867daed2847fcf"
timeout /t 1 >nul
start "" "https://codemagic.io/apps"
explorer "%DIR%"
pause