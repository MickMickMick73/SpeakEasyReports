@echo off
title SpeakEasy — FlutterFlow Browser
set "PATH=C:\Program Files\nodejs;%PATH%"
cd /d "%~dp0"
echo Opening FlutterFlow in a browser window...
node scripts/flutterflow-browser.mjs