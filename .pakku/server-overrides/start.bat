:: Copyright (C) 2025 Griefed
::
:: This script was modified by VioletEverbloom. You can find a link to the source and the script's licence in docs/CREDITS.md 


@ECHO OFF

PUSHD %~dp0

SET SCRIPTDIR=%~dp0
SET PSSCRIPTPATH=%SCRIPTDIR%start.ps1
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '%PSSCRIPTPATH%' %1";