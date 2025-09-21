@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Define the root server directory (no spaces)
SET ROOT_DIR=C:\rustserver

:: Server configuration

:: very important!, if your url has any '&' you need to add escapes  '^&"  
:: aka "https://dl.dropboxusercontent.com/s/stage28.map?idtest=test1&dl=1" should be "https://dl.dropboxusercontent.com/s/stage28.map?idtest=test1^&dl=1"
SET SERVER_LEVELURL="https://dl.dropboxusercontent.com/s/scl/fi/dugdxel9wcp7km6iyf75d/stage28.map?rlkey=79ac2tg5iqby8toxwnhmfh64f&st=h2w3v20w&dl=1"
:: set to true to use the SERVER_LEVELURL
SET USE_CUSTOM_MAP_URL="false"

SET SERVER_HOSTNAME="test server"
SET SERVER_DESCRIPTION="Just learning"
SET SERVER_URL="https://foxxservers.com"
SET SERVER_HEADERIMAGE="https://i.imgur.com/pR9YljG.png"
SET SERVER_TAGS="biweekly,NA,pve,z"
:: use https://whatismyip.com to find your public address
SET PUBLIC_IP="69.39.37.233"
:: The ip address inside your private network on your computer - use ipconfig to find it
SET PRIVATE_IP="192.168.11.57"
:: replace with your steamid, else I will be the owner! lol
SET OWNER_STEAM_ID="76561199753344979"
SET MODERATOR_STEAM_ID=""
:: this port needs to be open on your router/firewall for players to connect
SET GAMEPORT="28015"
:: this one too for the rust plus app
SET RUSTPLUSPORT="28017"
:: this can be the same as the rconport - used by game clients to get your server status
SET QUERYPORT="28016"
:: this can be the same as the queryport - if your hosting internally, you dont need this port to be open on your router.
SET RCONPORT="28016"
SET SERVER_SEED="9879815"
SET SERVER_WORLDSIZE="4500"
SET MAX_PLAYERS="10"
SET RCONPASSWORD="testicles"
:: number of seconds between map saves
SET SERVER_SAVE_INTERVAL="180"

:: Log file for RustDedicated.exe output
SET LOGFILE="%ROOT_DIR%\server\rust_server.log"

:: Create the root directory if it doesn't exist
if not exist "%ROOT_DIR%" (
    echo Creating root directory: %ROOT_DIR%
    mkdir "%ROOT_DIR%"
    if errorlevel 1 (
        echo Failed to create directory: %ROOT_DIR%
        pause
        exit /b 1
    )
)

:: Copy this batch file to the root directory for later use (if not already there)
set BATFILE=%ROOT_DIR%\%~nx0
if not exist "%BATFILE%" (
    echo Copying batch file to %ROOT_DIR% for future use...
    copy "%~f0" "%BATFILE%" >nul
    if errorlevel 1 (
        echo Warning: Failed to copy batch file to %ROOT_DIR%.
    ) else (
        echo Batch file copied successfully to %BATFILE%.
    )
)



:: Display custom map URL usage
if %USE_CUSTOM_MAP_URL%=="true" (
    echo Using custom map URL: %SERVER_LEVELURL%
) else (
    echo Not using custom map URL
)

:: Define paths
SET "SteamCmdPath=%ROOT_DIR%\steamcmd"
SET "FilePath=%SteamCmdPath%\steamcmd.exe"
SET "ZipPath=%SteamCmdPath%\steamcmd.zip"
SET "ServerPath=%ROOT_DIR%\server"
SET "OxideZipPath=%ServerPath%\Oxide.Rust.zip"

:: Check if steamcmd.exe exists
IF EXIST "%FilePath%" (
    echo The file "%FilePath%" exists.
) ELSE (
    echo The file "%FilePath%" does NOT exist, downloading steamcmd.zip
    :: Create directory if it doesn't exist
    if not exist "%SteamCmdPath%" (
        mkdir "%SteamCmdPath%" || (
            echo Failed to create directory "%SteamCmdPath%".
            exit /b 1
        )
    )
    :: Navigate to steamcmd directory
    pushd "%SteamCmdPath%" || (
        echo Failed to navigate to "%SteamCmdPath%".
        exit /b 1
    )
    :: Download steamcmd.zip
    echo Downloading steamcmd.zip...
    curl -L "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" --output "%ZipPath%" || (
        echo Failed to download steamcmd.zip.
        popd
        exit /b 1
    )
    :: Extract steamcmd.zip using PowerShell
    echo Extracting steamcmd.zip...
    powershell -Command "Expand-Archive -Path '%ZipPath%' -DestinationPath '%SteamCmdPath%' -Force" || (
        echo Failed to extract steamcmd.zip.
        popd
        exit /b 1
    )
    :: Delete the zip file
    del "%ZipPath%"
    popd
)

:: Navigate to steamcmd directory
pushd "%SteamCmdPath%" || (
    echo Failed to navigate to "%SteamCmdPath%".
    exit /b 1
)

:: Run steamcmd.exe to update itself (first run)
echo Running steamcmd.exe to ensure it's updated...
start /wait steamcmd.exe +quit

:: Add a short delay to ensure SteamCMD is ready
timeout /t 8 /nobreak >nul

:: Run steamcmd.exe to install/update the server
echo Installing/updating Rust server...
start /wait steamcmd.exe +force_install_dir "%ServerPath%" +login anonymous +app_update 258550 +quit

popd

:: Ensure server directory exists
if not exist "%ServerPath%" (
    echo Server directory "%ServerPath%" does not exist.
    exit /b 1
)

:: Install/Update Oxide
pushd "%ServerPath%" || (
    echo Failed to navigate to "%ServerPath%".
    exit /b 1
)
echo Downloading Oxide...
curl -L "https://umod.org/games/rust/download" --output "%OxideZipPath%" || (
    echo Failed to download Oxide.Rust.zip.
    popd
    exit /b 1
)
echo Extracting Oxide.Rust.zip...
powershell -Command "Expand-Archive -Path '%OxideZipPath%' -DestinationPath '%ServerPath%' -Force" || (
    echo Failed to extract Oxide.Rust.zip.
    popd
    exit /b 1
)
del "%OxideZipPath%"

:: Check if RustDedicated.exe exists
if not exist "%ServerPath%\RustDedicated.exe" (
    echo RustDedicated.exe not found in "%ServerPath%".
    popd
    exit /b 1
)

:: Start server loop
:start_server
echo Starting Rust server...
set "COMMAND=RustDedicated.exe -batchmode +server.level "Procedural Map" +server.seed %SERVER_SEED% +server.worldsize %SERVER_WORLDSIZE% +server.maxplayers %MAX_PLAYERS% +server.hostname %SERVER_HOSTNAME% +server.description %SERVER_DESCRIPTION% +server.url %SERVER_URL% +server.headerimage %SERVER_HEADERIMAGE% +server.identity "mapfiles" +rcon.port %RCONPORT% +server.port %GAMEPORT% +server.saveinterval %SERVER_SAVE_INTERVAL% +app.port %RUSTPLUSPORT% +app.publicip %PUBLIC_IP% +app.listenip %PRIVATE_IP% +server.tags %SERVER_TAGS% +rcon.password %RCONPASSWORD% +global.ownerid %OWNER_STEAM_ID% +global.moderatorid %MODERATOR_STEAM_ID% +rcon.web 1"
if %USE_CUSTOM_MAP_URL%=="true" (
    set COMMAND=%COMMAND% +server.levelurl %SERVER_LEVELURL%
)
echo Running: %COMMAND%
timeout /t 10
start /wait %COMMAND% >> "%LOGFILE%" 2>&1
echo Server stopped. Restarting in 10 seconds...
timeout /t 10 /nobreak >nul
goto start_server

popd
echo Done.
EXIT /B 0
