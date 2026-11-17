@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
echo ============================================================
echo   QWTF Live - Standalone Race Mode Compiler (Windows)
echo ============================================================

if exist "qwprogs.dat" del /f /q "qwprogs.dat"
if exist "csprogs.dat" del /f /q "csprogs.dat"
if exist "menu.dat" del /f /q "menu.dat"

set "FTEQCC="
if exist "fteqcc64.exe" (
    set "FTEQCC=.\fteqcc64.exe"
) else if exist "fteqcc.exe" (
    set "FTEQCC=.\fteqcc.exe"
) else if exist "..\fteqcc64.exe" (
    set "FTEQCC=..\fteqcc64.exe"
) else (
    where fteqcc64.exe >nul 2>nul
    if !ERRORLEVEL! EQU 0 (
        set "FTEQCC=fteqcc64.exe"
    ) else (
        where fteqcc.exe >nul 2>nul
        if !ERRORLEVEL! EQU 0 set "FTEQCC=fteqcc.exe"
    )
)

if "%FTEQCC%"=="" (
    echo [INFO] fteqcc64.exe not found locally. Downloading via PowerShell...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://fte.triptohell.info/moodles/win64/fteqcc64.exe' -OutFile 'fteqcc64.exe'"
    if exist "fteqcc64.exe" (
        set "FTEQCC=.\fteqcc64.exe"
    ) else (
        echo [ERROR] Could not find or download fteqcc64.exe.
        echo Please place fteqcc64.exe in this folder and run compile.bat again.
        pause
        exit /b 1
    )
)

echo Using compiler: %FTEQCC%
echo.

echo [1/3] Compiling Server QuakeC (qwprogs.dat)...
%FTEQCC% ./ssqc/progs.src
if not exist "qwprogs.dat" (
    echo [ERROR] Failed to compile ssqc/progs.src - qwprogs.dat was not generated!
    pause
    exit /b 1
)

echo [2/3] Compiling Client QuakeC (csprogs.dat)...
%FTEQCC% ./csqc/csprogs.src
if not exist "csprogs.dat" (
    echo [ERROR] Failed to compile csqc/csprogs.src - csprogs.dat was not generated!
    pause
    exit /b 1
)

echo [3/3] Compiling Menu QuakeC (menu.dat)...
%FTEQCC% ./menu/menu.src
if not exist "menu.dat" (
    echo [ERROR] Failed to compile menu/menu.src - menu.dat was not generated!
    pause
    exit /b 1
)

REM Automatically deploy compiled .dat files if fortress\ exists nearby
for %%D in ("fortress" "..\fortress" "..\..\fortress" "C:\FOSV\fortress") do (
    if exist "%%~D\" (
        echo [DEPLOY] Copying qwprogs.dat, csprogs.dat, menu.dat to %%~fD\ ...
        copy /y "qwprogs.dat" "%%~D\qwprogs.dat" >nul
        copy /y "qwprogs.dat" "%%~D\progs.dat" >nul
        copy /y "csprogs.dat" "%%~D\csprogs.dat" >nul
        copy /y "menu.dat" "%%~D\menu.dat" >nul
        if not exist "%%~D\race_server.cfg" (
            copy /y "race_server.cfg" "%%~D\race_server.cfg" >nul
        )
    )
)

echo.
echo ============================================================
echo   SUCCESS! Generated:
echo     - qwprogs.dat
echo     - csprogs.dat
echo     - menu.dat
echo   Make sure these 3 files are inside your server's fortress\ folder!
echo ============================================================
