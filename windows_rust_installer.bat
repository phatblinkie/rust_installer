@echo off
SETLOCAL EnableExtensions EnableDelayedExpansion

:: ============================================================
:: Rust Server Menu - vers: 1.4.0
:: Windows 10+ native tools only (cmd, PowerShell, curl, robocopy, forfiles)
:: Tasks:
::  1) Install/Reinstall SteamCMD
::  2) Install/Update Rust (AppID 258550)
::  3) Install/Update Oxide (uMod)
::  4) Install latest RustEdit extension DLL
::  5) Install latest Discord extension DLL
::  6) Install latest Chaoscode extension DLL
::  7) Force backup now
::  8) Stop Rust server (requests exit; blocks restart)
::  9) Start Rust server (restart-on-exit loop; performs backup on exit)
:: ============================================================

SET "SCRIPT_VERSION=1.4.0"

:: -------------------------------
:: Root install directory (no spaces recommended)
SET "ROOT_DIR=C:\rustserver"
:: -------------------------------

:: -------------------------------
:: Server configuration (raw values; DO NOT wrap these in quotes)
SET "SERVER_LEVELURL=http://209.222.101.108/maps/testmapbeta.v2.map"
SET "USE_CUSTOM_MAP_URL=false"

SET "SERVER_HOSTNAME=phats test server"
SET "SERVER_DESCRIPTION=Just learning"
SET "SERVER_URL=https://foxxservers.com"
SET "SERVER_HEADERIMAGE=https://i.imgur.com/pR9YljG.png"
SET "SERVER_TAGS=biweekly,NA,pve,z"

:: Public and private IPs
SET "PUBLIC_IP=69.39.37.233"
SET "PRIVATE_IP=192.168.11.57"

:: Admins
SET "OWNER_STEAM_ID=76561199753344979"
SET "MODERATOR_STEAM_ID="

:: Ports
SET "GAMEPORT=28015"
SET "RUSTPLUSPORT=28017"
SET "QUERYPORT=28016"
SET "RCONPORT=28016"

:: World/settings
SET "SERVER_SEED=9879815"
SET "SERVER_WORLDSIZE=4500"
SET "MAX_PLAYERS=10"
SET "RCONPASSWORD=testicles"
SET "SERVER_SAVE_INTERVAL=180"

:: Game log file name (written in the server folder)
SET "GAME_LOGFILE=logfile.txt"
:: -------------------------------

:: Backups
SET "BACKUP_DIR=%ROOT_DIR%\backups"
SET "BACKUP_RETENTION_DAYS=7"   :: number of days of backups to keep
:: -------------------------------

:: Paths
SET "SteamCmdPath=%ROOT_DIR%\steamcmd"
SET "SteamCmdExe=%SteamCmdPath%\steamcmd.exe"
SET "SteamCmdZip=%SteamCmdPath%\steamcmd.zip"
SET "ServerPath=%ROOT_DIR%\server"
SET "OxideZipPath=%ServerPath%\Oxide.Rust.zip"

:: Downloads
SET "STEAMCMD_URL=https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip"
SET "OXIDE_URL=https://umod.org/games/rust/download"
SET "RUSTEDIT_URL=https://raw.githubusercontent.com/k1lly0u/Oxide.Ext.RustEdit/refs/heads/master/Oxide.Ext.RustEdit.dll"
SET "DISCORD_URL=https://umod.org/extensions/discord/download"
SET "CHAOS_URL=https://oxide.chaoscode.io/Oxide.Ext.Chaos.dll"

:: Destinations for extensions
SET "MANAGED_DIR=%ServerPath%\RustDedicated_Data\Managed"
SET "RUSTEDIT_DEST=%MANAGED_DIR%\Oxide.Ext.RustEdit.dll"
SET "DISCORD_DEST=%MANAGED_DIR%\Oxide.Ext.Discord.dll"
SET "CHAOS_DEST=%MANAGED_DIR%\Oxide.Ext.Chaos.dll"

:: Stop flag (prevents restart in loop)
SET "STOP_FLAG=%ROOT_DIR%\stop.flag"

:: Copy this script to ROOT_DIR for convenience (once)
IF NOT EXIST "%ROOT_DIR%" (
    mkdir "%ROOT_DIR%" 2>nul
)
IF EXIST "%ROOT_DIR%" (
    SET "SELF_COPY=%ROOT_DIR%\%~nx0"
    IF NOT EXIST "%SELF_COPY%" (
        copy "%~f0" "%SELF_COPY%" >nul
    )
)

:: ------------------------------------------------------------
:: Menu loop
:menu
cls
echo ===============================================
echo Rust Server Menu - vers: %SCRIPT_VERSION%
echo Root: %ROOT_DIR%
echo Server: %ServerPath%
echo Game log: %ServerPath%\%GAME_LOGFILE%
echo ===============================================
echo.
echo  1) Install/Reinstall SteamCMD
echo  2) Install/Update Rust dedicated server (AppID 258550)
echo  3) Install/Update Oxide (uMod)
echo  4) Install latest RustEdit extension DLL
echo  5) Install latest Discord extension DLL
echo  6) Install latest Chaoscode extension DLL
echo  7) Force backup now
echo  8) Stop Rust server (requests exit; blocks restart)
echo  9) Start Rust server (restart-on-exit loop)
echo -----------------------------------------------
echo  A) Show current config summary
echo  R) Reload menu
echo  E) Exit
echo.
set "choice="
set /p choice=Select an option and press Enter: 

if /I "%choice%"=="1" goto task_install_steamcmd
if /I "%choice%"=="2" goto task_install_rust
if /I "%choice%"=="3" goto task_install_oxide
if /I "%choice%"=="4" goto task_install_rustedit
if /I "%choice%"=="5" goto task_install_discord
if /I "%choice%"=="6" goto task_install_chaos
if /I "%choice%"=="7" goto task_force_backup
if /I "%choice%"=="8" goto task_stop_server
if /I "%choice%"=="9" goto task_start_server
if /I "%choice%"=="A" goto show_config
if /I "%choice%"=="R" goto menu
if /I "%choice%"=="E" goto end

echo.
echo Invalid selection: "%choice%"
call :press_any_key
goto menu

:: ------------------------------------------------------------
:show_config
cls
setlocal DisableDelayedExpansion
echo -------- Configuration Summary --------
echo ROOT_DIR             = "%ROOT_DIR%"
echo SteamCmdPath         = "%SteamCmdPath%"
echo ServerPath           = "%ServerPath%"
echo USE_CUSTOM_MAP_URL   = "%USE_CUSTOM_MAP_URL%"
echo SERVER_LEVELURL      = "%SERVER_LEVELURL%"
echo SERVER_HOSTNAME      = "%SERVER_HOSTNAME%"
echo SERVER_DESCRIPTION   = "%SERVER_DESCRIPTION%"
echo SERVER_URL           = "%SERVER_URL%"
echo SERVER_HEADERIMAGE   = "%SERVER_HEADERIMAGE%"
echo SERVER_TAGS          = "%SERVER_TAGS%"
echo PUBLIC_IP            = "%PUBLIC_IP%"
echo PRIVATE_IP           = "%PRIVATE_IP%"
echo OWNER_STEAM_ID       = "%OWNER_STEAM_ID%"
echo MODERATOR_STEAM_ID   = "%MODERATOR_STEAM_ID%"
echo GAMEPORT             = "%GAMEPORT%"
echo RUSTPLUSPORT         = "%RUSTPLUSPORT%"
echo QUERYPORT            = "%QUERYPORT%"
echo RCONPORT             = "%RCONPORT%"
echo SERVER_SEED          = "%SERVER_SEED%"
echo SERVER_WORLDSIZE     = "%SERVER_WORLDSIZE%"
echo MAX_PLAYERS          = "%MAX_PLAYERS%"
echo RCONPASSWORD         = "%RCONPASSWORD%"
echo SERVER_SAVE_INT      = "%SERVER_SAVE_INTERVAL% seconds"
echo MANAGED_DIR          = "%MANAGED_DIR%"
echo RUSTEDIT_DEST        = "%RUSTEDIT_DEST%"
echo DISCORD_DEST         = "%DISCORD_DEST%"
echo CHAOS_DEST           = "%CHAOS_DEST%"
echo BACKUP_DIR           = "%BACKUP_DIR%"
echo BACKUP_RETENTION     = "%BACKUP_RETENTION_DAYS% days"
echo GAME_LOGFILE         = "%GAME_LOGFILE%"
echo STOP_FLAG            = "%STOP_FLAG%"
echo ---------------------------------------
endlocal
echo.
call :press_any_key
goto menu

:: ------------------------------------------------------------
:: Step 1: Install/Reinstall SteamCMD
:task_install_steamcmd
cls
echo [1/9] Install/Reinstall SteamCMD
echo Target: %SteamCmdExe%
echo.

call :ensure_dir "%SteamCmdPath%"
if errorlevel 1 goto fail_step

echo Downloading SteamCMD...
call :download "%STEAMCMD_URL%" "%SteamCmdZip%"
if errorlevel 1 goto fail_step

echo Extracting SteamCMD...
call :extract "%SteamCmdZip%" "%SteamCmdPath%"
if errorlevel 1 goto fail_step

del /f /q "%SteamCmdZip%" 2>nul

if not exist "%SteamCmdExe%" (
    echo ERROR: steamcmd.exe not found after extraction.
    goto fail_step
)

echo Running SteamCMD once to update itself...
pushd "%SteamCmdPath%" >nul
start "" /wait "%SteamCmdExe%" +quit
popd >nul

echo.
echo SteamCMD installed/updated successfully.
call :press_any_key
goto menu

:: ------------------------------------------------------------
:: Step 2: Install/Update Rust dedicated server
:task_install_rust
cls
echo [2/9] Install/Update Rust Dedicated Server (AppID 258550)
echo.

if not exist "%SteamCmdExe%" (
    echo SteamCMD not found. Running Step 1 automatically...
    call :task_install_steamcmd
)

call :ensure_dir "%ServerPath%"
if errorlevel 1 goto fail_step

echo Installing/Updating Rust (this can take a while)...
pushd "%SteamCmdPath%" >nul
start "" /wait "%SteamCmdExe%" +force_install_dir "%ServerPath%" +login anonymous +app_update 258550 validate +quit
set "sc_er=%ERRORLEVEL%"
popd >nul

if not exist "%ServerPath%\RustDedicated.exe" (
    echo ERROR: RustDedicated.exe not found in "%ServerPath%".
    goto fail_step
)

echo.
echo Rust server installed/updated successfully. ExitCode=%sc_er%
call :press_any_key
goto menu

:: ------------------------------------------------------------
:: Step 3: Install/Update Oxide (uMod)
:task_install_oxide
cls
echo [3/9] Install/Update Oxide (uMod)
echo.

if not exist "%ServerPath%\RustDedicated.exe" (
    echo ERROR: Rust not installed yet. Run Step 2 first.
    goto pause_return
)

echo Downloading Oxide from %OXIDE_URL%
call :download "%OXIDE_URL%" "%OxideZipPath%"
if errorlevel 1 goto fail_step

echo Extracting Oxide into "%ServerPath%" ...
call :extract "%OxideZipPath%" "%ServerPath%"
if errorlevel 1 goto fail_step

del /f /q "%OxideZipPath%" 2>nul

echo.
echo Oxide installed/updated successfully.
call :press_any_key
goto menu

:: ------------------------------------------------------------
:: Step 4: Install latest RustEdit extension DLL
:task_install_rustedit
cls
echo [4/9] Install RustEdit extension DLL
echo Source: %RUSTEDIT_URL%
echo Dest  : %RUSTEDIT_DEST%
echo.

if not exist "%ServerPath%\RustDedicated.exe" (
    echo ERROR: Rust not installed yet. Run Step 2 first.
    goto pause_return
)

call :ensure_dir "%MANAGED_DIR%"
if errorlevel 1 goto fail_step

echo Downloading RustEdit extension...
call :download "%RUSTEDIT_URL%" "%RUSTEDIT_DEST%"
if errorlevel 1 goto fail_step

echo.
echo RustEdit extension installed at:
echo %RUSTEDIT_DEST%
call :press_any_key
goto menu

:: ------------------------------------------------------------
:: Step 5: Install latest Discord extension DLL
:task_install_discord
cls
echo [5/9] Install Discord extension DLL
echo Source: %DISCORD_URL%
echo Dest  : %DISCORD_DEST%
echo.

if not exist "%ServerPath%\RustDedicated.exe" (
    echo ERROR: Rust not installed yet. Run Step 2 first.
    goto pause_return
)

call :ensure_dir "%MANAGED_DIR%"
if errorlevel 1 goto fail_step

call :install_ext_from_url "%DISCORD_URL%" "Oxide.Ext.Discord.dll"
if errorlevel 1 goto fail_step

echo.
echo Discord extension installed at:
echo %DISCORD_DEST%
call :press_any_key
goto menu

:: ------------------------------------------------------------
:: Step 6: Install latest Chaoscode extension DLL
:task_install_chaos
cls
echo [6/9] Install Chaoscode extension DLL
echo Source: %CHAOS_URL%
echo Dest  : %CHAOS_DEST%
echo.

if not exist "%ServerPath%\RustDedicated.exe" (
    echo ERROR: Rust not installed yet. Run Step 2 first.
    goto pause_return
)

call :ensure_dir "%MANAGED_DIR%"
if errorlevel 1 goto fail_step

call :install_ext_from_url "%CHAOS_URL%" "Oxide.Ext.Chaos.dll"
if errorlevel 1 goto fail_step

echo.
echo Chaoscode extension installed at:
echo %CHAOS_DEST%
call :press_any_key
goto menu

:: ------------------------------------------------------------
:: Step 7: Force backup now
:task_force_backup
cls
echo [7/9] Force backup now

:: Refuse to back up if the server is running (to avoid corruption)
tasklist /FI "IMAGENAME eq RustDedicated.exe" | find /I "RustDedicated.exe" >nul
if %ERRORLEVEL%==0 goto backup_blocked

echo Creating backup snapshot...
call :do_backup
if errorlevel 1 (
    echo Backup failed.
    goto pause_return
)
echo Backup complete. Applying retention policy (%BACKUP_RETENTION_DAYS% days)...
call :prune_backups
echo Retention pruning complete.
call :press_any_key
goto menu

:backup_blocked
echo.
echo WARNING: Copying the server data while RustDedicated.exe is running will result in corrupted data.
echo Backups are blocked while the server is running.
echo.
echo How to proceed:
echo  - If you are using option 9 restart loop, wait for the server to exit.
echo  - During the 10-second countdown, press Ctrl+C to stop the loop.
echo  - Then return here and run "7) Force backup now".
goto pause_return

:: ------------------------------------------------------------
:: Step 8: Stop Rust server (requests exit; blocks restart)
:task_stop_server
cls
echo [8/9] Stop Rust server

:: Set the stop flag so the restart loop (option 9) will not restart
echo stop > "%STOP_FLAG%" 2>nul

:: If not running, we're done
tasklist /FI "IMAGENAME eq RustDedicated.exe" | find /I "RustDedicated.exe" >nul
if %ERRORLEVEL% NEQ 0 (
    echo RustDedicated.exe is not running. Restart is blocked until you start it again.
    goto pause_return
)

echo Requesting process to exit gracefully...
:: No /F (force) here — we want a clean shutdown
taskkill /IM RustDedicated.exe >nul 2>&1

echo Waiting up to 60 seconds for exit...
for /L %%S in (1,1,60) do (
    tasklist /FI "IMAGENAME eq RustDedicated.exe" | find /I "RustDedicated.exe" >nul
    if ERRORLEVEL 1 goto server_stopped_msg
    timeout /t 1 >nul
)

echo.
echo Timed out waiting for exit. The server may still be stopping.
echo Restart is blocked; try again in a few seconds, or close the server window manually.
goto pause_return

:server_stopped_msg
echo.
echo Server process has exited. A backup will run automatically if it was launched via option 9.
echo Since restart is blocked, the loop will return to the menu after backup completes.
goto pause_return

:: ------------------------------------------------------------
:: Step 9: Start server (restart-on-exit loop) — robust quoting, with backups on exit, honors stop flag
:task_start_server
cls
echo [9/9] Start Rust Server
echo Game log -> %ServerPath%\%GAME_LOGFILE%
echo.

if not exist "%ServerPath%\RustDedicated.exe" (
    echo ERROR: RustDedicated.exe not found. Run Step 2 first.
    goto pause_return
)

call :ensure_dir "%ServerPath%"
call :ensure_dir "%BACKUP_DIR%"

:: Avoid ! expansion issues in args (passwords, descriptions, etc.)
setlocal DisableDelayedExpansion

pushd "%ServerPath%" >nul

:: Friendly variable for the level name
set "LEVEL_NAME=Procedural Map"

echo Starting loop in 10 seconds... Press Ctrl+C to cancel.
timeout /t 10 /nobreak >nul

:start_server_loop
echo.
echo ===== Launching RustDedicated.exe =====

set "CMD_PATH=%ServerPath%\RustDedicated.exe"

:: Show the command that will run (no -swnet; includes +logfile)
echo "%CMD_PATH%" -batchmode ^
 +server.level "%LEVEL_NAME%" ^
 +server.seed %SERVER_SEED% ^
 +server.worldsize %SERVER_WORLDSIZE% ^
 +server.maxplayers %MAX_PLAYERS% ^
 +server.hostname "%SERVER_HOSTNAME%" ^
 +server.description "%SERVER_DESCRIPTION%" ^
 +server.url "%SERVER_URL%" ^
 +server.headerimage "%SERVER_HEADERIMAGE%" ^
 +server.identity "mapfiles" ^
 +rcon.port %RCONPORT% ^
 +server.port %GAMEPORT% ^
 +server.saveinterval %SERVER_SAVE_INTERVAL% ^
 +app.port %RUSTPLUSPORT% ^
 +app.publicip %PUBLIC_IP% ^
 +app.listenip %PRIVATE_IP% ^
 +server.tags "%SERVER_TAGS%" ^
 +rcon.password "%RCONPASSWORD%" ^
 +global.ownerid %OWNER_STEAM_ID% ^
 +global.moderatorid %MODERATOR_STEAM_ID% ^
 +rcon.web 1 ^
 +queryport %QUERYPORT% ^
 +logfile "%GAME_LOGFILE%"
if /I "%USE_CUSTOM_MAP_URL%"=="true" echo +server.levelurl ENABLED

:: Execute (branch to include optional levelurl cleanly)
if /I "%USE_CUSTOM_MAP_URL%"=="true" (
    start "" /wait "%CMD_PATH%" -batchmode ^
        +server.level "%LEVEL_NAME%" ^
        +server.seed %SERVER_SEED% ^
        +server.worldsize %SERVER_WORLDSIZE% ^
        +server.maxplayers %MAX_PLAYERS% ^
        +server.hostname "%SERVER_HOSTNAME%" ^
        +server.description "%SERVER_DESCRIPTION%" ^
        +server.url "%SERVER_URL%" ^
        +server.headerimage "%SERVER_HEADERIMAGE%" ^
        +server.identity "mapfiles" ^
        +rcon.port %RCONPORT% ^
        +server.port %GAMEPORT% ^
        +server.saveinterval %SERVER_SAVE_INTERVAL% ^
        +app.port %RUSTPLUSPORT% ^
        +app.publicip %PUBLIC_IP% ^
        +app.listenip %PRIVATE_IP% ^
        +server.tags "%SERVER_TAGS%" ^
        +rcon.password "%RCONPASSWORD%" ^
        +global.ownerid %OWNER_STEAM_ID% ^
        +global.moderatorid %MODERATOR_STEAM_ID% ^
        +rcon.web 1 ^
        +queryport %QUERYPORT% ^
        +logfile "%GAME_LOGFILE%" ^
        +server.levelurl "%SERVER_LEVELURL%"
) ELSE (
    start "" /wait "%CMD_PATH%" -batchmode ^
        +server.level "%LEVEL_NAME%" ^
        +server.seed %SERVER_SEED% ^
        +server.worldsize %SERVER_WORLDSIZE% ^
        +server.maxplayers %MAX_PLAYERS% ^
        +server.hostname "%SERVER_HOSTNAME%" ^
        +server.description "%SERVER_DESCRIPTION%" ^
        +server.url "%SERVER_URL%" ^
        +server.headerimage "%SERVER_HEADERIMAGE%" ^
        +server.identity "mapfiles" ^
        +rcon.port %RCONPORT% ^
        +server.port %GAMEPORT% ^
        +server.saveinterval %SERVER_SAVE_INTERVAL% ^
        +app.port %RUSTPLUSPORT% ^
        +app.publicip %PUBLIC_IP% ^
        +app.listenip %PRIVATE_IP% ^
        +server.tags "%SERVER_TAGS%" ^
        +rcon.password "%RCONPASSWORD%" ^
        +global.ownerid %OWNER_STEAM_ID% ^
        +global.moderatorid %MODERATOR_STEAM_ID% ^
        +rcon.web 1 ^
        +queryport %QUERYPORT% ^
        +logfile "%GAME_LOGFILE%"
)

echo.
echo Server process exited.

:: ---------------- Backups on exit ----------------
echo Creating backup snapshot before restart...
call :do_backup
echo Backup complete. Applying retention policy (%BACKUP_RETENTION_DAYS% days)...
call :prune_backups
echo Retention pruning complete.
:: -----------------------------------------------

:: Honor stop flag: do not restart if requested
if exist "%STOP_FLAG%" (
    echo Stop requested — not restarting. Returning to menu.
    del "%STOP_FLAG%" >nul 2>&1
    goto end_server_loop
)

echo Restarting in 10 seconds...
timeout /t 10 /nobreak >nul
goto start_server_loop

:end_server_loop
popd >nul
endlocal
goto menu

:: ------------------------------------------------------------
:: Utilities

:ensure_dir
:: %1 = path
if "%~1"=="" exit /b 1
if exist "%~1" exit /b 0
mkdir "%~1" 2>nul
if errorlevel 1 (
    echo ERROR: Failed to create directory "%~1"
    exit /b 1
)
exit /b 0

:download
:: %1 = URL, %2 = outFile
set "_url=%~1"
set "_out=%~2"
if "%_url%"=="" exit /b 1
if "%_out%"=="" exit /b 1

echo Downloading:
echo   %_url%
echo   -> %_out%

:: Prefer curl if present
where curl >nul 2>nul
if %ERRORLEVEL%==0 (
    curl -L "%_url%" --output "%_out%"
    if errorlevel 1 (
        echo curl download failed.
        goto dl_fallback
    ) else (
        exit /b 0
    )
)

:dl_fallback
:: Force TLS 1.2 for reliability
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri '%_url%' -OutFile '%_out%' -UseBasicParsing } catch { $host.SetShouldExit(1) }"
if errorlevel 1 (
    echo ERROR: Download failed for %_url%
    exit /b 1
)
exit /b 0

:extract
:: %1 = zipPath, %2 = dest
if not exist "%~1" (
    echo ERROR: Archive not found: %~1
    exit /b 1
)
powershell -NoProfile -Command "try { Expand-Archive -Path '%~1' -DestinationPath '%~2' -Force } catch { $host.SetShouldExit(1) }"
if errorlevel 1 (
    echo ERROR: Failed to extract: %~1
    exit /b 1
)
exit /b 0

:install_ext_from_url
:: %1 = URL
:: %2 = Expected DLL filename (e.g., Oxide.Ext.Discord.dll)
set "_url=%~1"
set "_dllname=%~2"
set "_dest=%MANAGED_DIR%\%_dllname%"
set "_tmp=%ServerPath%\_tmp_ext"
set "_payload=%_tmp%\payload.bin"
set "_unz=%_tmp%\unzipped"

:: Prep temp
if exist "%_tmp%" rmdir /S /Q "%_tmp%" >nul 2>&1
mkdir "%_tmp%" >nul 2>&1
if errorlevel 1 (
    echo ERROR: Could not create temp directory "%_tmp%".
    exit /b 1
)

echo Downloading extension package...
call :download "%_url%" "%_payload%"
if errorlevel 1 (
    echo ERROR: Download failed.
    if exist "%_tmp%" rmdir /S /Q "%_tmp%" >nul 2>&1
    exit /b 1
)

:: Try to unzip; if not a zip, Expand-Archive will fail and we fall back to raw DLL copy.
powershell -NoProfile -Command "try { Expand-Archive -Path '%_payload%' -DestinationPath '%_unz%' -Force; $host.SetShouldExit(0) } catch { $host.SetShouldExit(1) }"
if errorlevel 1 (
    echo Package is not a ZIP; assuming raw DLL.
    copy /Y "%_payload%" "%_dest%" >nul
    if errorlevel 1 (
        echo ERROR: Failed to copy extension to "%_dest%".
        if exist "%_tmp%" rmdir /S /Q "%_tmp%" >nul 2>&1
        exit /b 1
    )
) else (
    echo Extracted package; locating DLL...
    set "COPIED="
    if exist "%_unz%\%_dllname%" (
        copy /Y "%_unz%\%_dllname%" "%_dest%" >nul
        if not errorlevel 1 set "COPIED=1"
    )
    if not defined COPIED (
        for /r "%_unz%" %%F in (*.dll) do (
            if not defined COPIED (
                copy /Y "%%~fF" "%_dest%" >nul
                if not errorlevel 1 set "COPIED=1"
            )
        )
    )
    if not defined COPIED (
        echo ERROR: No DLL was found in the extracted package.
        if exist "%_tmp%" rmdir /S /Q "%_tmp%" >nul 2>&1
        exit /b 1
    )
)

:: Cleanup temp
if exist "%_tmp%" rmdir /S /Q "%_tmp%" >nul 2>&1

echo Installed: %_dest%
exit /b 0

:do_backup
:: Creates timestamped backup of %ServerPath%\oxide and %ServerPath%\server
:: Safety: never back up while the server process is running
tasklist /FI "IMAGENAME eq RustDedicated.exe" | find /I "RustDedicated.exe" >nul
if %ERRORLEVEL%==0 (
    echo.
    echo WARNING: RustDedicated.exe is running — backup aborted to prevent corrupted data.
    exit /b 1
)

call :ensure_dir "%BACKUP_DIR%"
if errorlevel 1 exit /b 1

for /f %%I in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "STAMP=%%I"
set "BK=%BACKUP_DIR%\%STAMP%"
set "BK_OX=%BK%\oxide"
set "BK_SV=%BK%\server"

echo Backup target: %BK%
call :ensure_dir "%BK%"
call :ensure_dir "%BK_OX%"
call :ensure_dir "%BK_SV%"

:: Copy oxide directory if it exists
if exist "%ServerPath%\oxide" (
    echo Backing up "oxide"...
    robocopy "%ServerPath%\oxide" "%BK_OX%" /E /R:1 /W:1 /NFL /NDL /NP /NJH /NJS >nul
    if errorlevel 8 (
        echo WARNING: robocopy reported an error backing up "oxide".
    )
) else (
    echo Skipping "oxide" — source not found.
)

:: Copy server directory if it exists
if exist "%ServerPath%\server" (
    echo Backing up "server"...
    robocopy "%ServerPath%\server" "%BK_SV%" /E /R:1 /W:1 /NFL /NDL /NP /NJH /NJS >nul
    if errorlevel 8 (
        echo WARNING: robocopy reported an error backing up "server".
    )
) else (
    echo Skipping "server" — source not found.
)

echo Backup created at: %BK%
exit /b 0

:prune_backups
:: Deletes backup folders older than BACKUP_RETENTION_DAYS
if not exist "%BACKUP_DIR%" exit /b 0
echo Pruning backups older than %BACKUP_RETENTION_DAYS% days:
forfiles /P "%BACKUP_DIR%" /D -%BACKUP_RETENTION_DAYS% /C "cmd /c if @isdir==TRUE echo @file & rmdir /S /Q @path"
exit /b 0

:press_any_key
echo.
pause
exit /b 0

:pause_return
echo.
pause
goto menu

:fail_step
echo.
echo ---------- Step failed ----------
echo Check the messages above and try again.
echo ---------------------------------
echo.
pause
goto menu

:end
echo Exiting.
ENDLOCAL
exit /b 0
