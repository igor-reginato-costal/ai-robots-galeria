@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync-and-push.ps1"
exit /b %ERRORLEVEL%
