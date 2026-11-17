@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
echo [%date% %time%] Window opened >> "%~dp0server_exit.log"
echo ============================================================
echo   Starting QWTF Live - Race Mode Server (Windows)
echo ============================================================

REM 1. Locate FTEQW / FortressOne server executable
set "SV_BIN="
if exist "fortressonesv64.exe" (
    set "SV_BIN=fortressonesv64.exe"
) else if exist "fteqwsv64.exe" (
    set "SV_BIN=fteqwsv64.exe"
) else if exist "fteqw64.exe" (
    set "SV_BIN=fteqw64.exe -dedicated 16"
) else (
    echo [ERROR] Could not find fortressonesv64.exe, fteqwsv64.exe, or fteqw64.exe in:
    echo         %CD%
    echo Please place this .bat file in the same folder as your FTE server .exe!
    pause
    exit /b 1
)

if not exist "fortress\" mkdir "fortress"

REM 2. Auto-copy compiled qwprogs.dat / csprogs.dat / menu.dat if they are in the current folder
if exist "qwprogs.dat" (
    echo [INFO] Copying qwprogs.dat into fortress\ ...
    copy /y "qwprogs.dat" "fortress\qwprogs.dat" >nul
    copy /y "qwprogs.dat" "fortress\progs.dat" >nul
)
if exist "csprogs.dat" (
    echo [INFO] Copying csprogs.dat into fortress\ ...
    copy /y "csprogs.dat" "fortress\csprogs.dat" >nul
)
if exist "menu.dat" (
    echo [INFO] Copying menu.dat into fortress\ ...
    copy /y "menu.dat" "fortress\menu.dat" >nul
)
if not exist "fortress\race_server.cfg" (
    if exist "race_server.cfg" (
        copy /y "race_server.cfg" "fortress\race_server.cfg" >nul
    )
)

REM 3. Verify that fortress\qwprogs.dat exists so FTE never falls back to NetQuake id1/progs.dat!
if not exist "fortress\qwprogs.dat" (
    echo.
    echo [ERROR] fortress\qwprogs.dat WAS NOT FOUND!
    echo         Without fortress\qwprogs.dat, FTE falls back to vanilla NetQuake progs.dat,
    echo         which causes "Couldn't find spawn function for info_tfgoal" and disables
    echo         QuakeWorld movement prediction.
    echo.
    echo         Fix: Run compile.bat first, then copy qwprogs.dat, csprogs.dat, and menu.dat
    echo         into "%CD%\fortress\" and run this script again.
    pause
    exit /b 1
)

REM Ensure progs.dat inside fortress\ also matches qwprogs.dat
copy /y "fortress\qwprogs.dat" "fortress\progs.dat" >nul

REM 4. Launch server in QuakeWorld fortress mode and exec race_server.cfg
REM    (Note: Do NOT pass +map here so the 'map' line inside race_server.cfg is respected!)
%SV_BIN% +gamedir fortress +set sv_progs "qwprogs.dat" +set sv_nqplayerphysics 0 +set sv_public 1 +set com_protocolname FortressOne +set com_protocolversion 3 +set sv_gamename "FortressOne" +serverinfo gametype "qwtflive" +exec race_server.cfg
echo [%date% %time%] Server exited, code %errorlevel% >> "%~dp0server_exit.log"
pause
