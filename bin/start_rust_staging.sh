#!/bin/bash
cd ~/rust_staging/ || { echo "Failed to change to ~/rust_staging"; exit 1; }
. rust-staging-settings.conf


function update_rust_staging() {
    ~/Steam/steamcmd.sh +force_install_dir ~/rust_staging/ +login anonymous +app_update 258550 -beta staging validate +exit
    #do it again, sometimes it does not update properly,
    ~/Steam/steamcmd.sh +force_install_dir ~/rust_staging/ +login anonymous +app_update 258550 -beta staging validate +exit
}

function update_oxide() {
    cd ~/rust_staging/ || { echo "Failed to change to ~/rust_staging"; exit 1; }
    wget -O oxide.zip https://downloads.oxidemod.com/artifacts/Oxide.Rust/staging/Oxide.Rust-linux.zip
    if [ $? -ne 0 ]; then
        echo "Failed to download Oxide"
        exit 1
    fi
    unzip -o oxide.zip
    if [ $? -ne 0 ]; then
        echo "Failed to unzip Oxide"
        exit 1
    fi
    echo "Oxide update completed"
    sleep 3
}

function make_backup() {
    cd ~/rust_staging/ || { echo "Failed to change to ~/rust_staging"; exit 1; }
    echo "Creating backup at $(date)"
    mkdir -p ~/backups/
    rsync -avh --progress server ~/backups/"$(date +'%B-%d_%H%M%p')/"
    rsync -avh --progress oxide ~/backups/"$(date +'%B-%d_%H%M%p')/"
    echo "Deleting backups older than $DAYS_OF_BACKUPS days"
    find ~/backups/ -type f -mtime +"$DAYS_OF_BACKUPS" -delete -print
    find ~/backups/ -type d -empty -delete -print
}

function run_rust_custom_map() {
    mkdir -p ~/rust_staging/server/jan1/cfg
    echo -e "$SERVERAUTO_CFG" > ~/rust_staging/server/jan1/cfg/server.cfg
    echo -e "$USERS_CFG" > ~/rust_staging/server/jan1/cfg/users.cfg
    echo "Starting Rust Staging server (custom map)"
   #lets not update oxide each restart, let the user do this with the installer menu
    #update_oxide
    exec ./RustDedicated -batchmode -nographics \
        +server.ip "$IP" \
        +server.port "$GAMEPORT" \
        +server.queryport "$QUERYPORT" \
        +rcon.ip "$IP" \
        +rcon.web "1" \
        +rcon.port "$RCONPORT" \
        +rcon.password "$RCONPASS" \
        +server.maxplayers "$PLAYERLIMIT" \
        +server.hostname "$SERVER_HOSTNAME" \
        +server.identity "$MODFOLDER" \
        +server.worldsize "$MAPSIZE" \
        +server.seed "$MAPSEED" \
        +server.saveinterval 180 \
        +app.port "$RUSTPLUSPORT" \
        +app.listenip "$IP" \
        +app.publicip "$IP" \
        +server.secure "true" \
        +server.tickrate "30" \
        +fps.limit "100" \
        +server.pve "false" \
        +chat.enabled "True" \
        +chat.globalchat "True" \
        +server.idlekickmode "1" \
        +server.idlekick "0" \
        +server.idlekickadmins "0" \
        +decay.scale "0.2" \
        +xmas.enabled "0" \
        +decay.upkeep "true" \
        +nav_disable "false" \
        +server.encryption "2" \
        +server.tags "$TAGS" \
        +global.moderatorid "$MODERATORID" \
        +global.ownerid "$OWNERID" \
        +server.description "$DESCRIPTION" \
        +server.level "$MAPLEVEL" \
        +server.headerimage "$HEADERIMAGE" \
        +server.url "$SERVER_URL" \
        +server.gamemode "$SERVER_GAMEMODE" \
        +server.motd "$SERVER_MOTD" \
        +server.levelurl "$SERVER_LEVELURL" \
        +server.writecfg
    if [ $PERFORM_BACKUPS -eq 1 ]; then
        make_backup
    fi
}

function run_rust_standard_map() {
    mkdir -p ~/rust_staging/server/jan1/cfg
    echo -e "$SERVERAUTO_CFG" > ~/rust_staging/server/jan1/cfg/server.cfg
    echo -e "$USERS_CFG" > ~/rust_staging/server/jan1/cfg/users.cfg
    echo "Starting Rust Staging server (standard map)"
    #lets not update oxide each restart, let the user do this with the installer menu
    #update_oxide
    exec ./RustDedicated -batchmode -nographics \
        +server.ip "$IP" \
        +server.port "$GAMEPORT" \
        +server.queryport "$QUERYPORT" \
        +rcon.ip "$IP" \
        +rcon.port "$RCONPORT" \
        +rcon.web "1" \
        +rcon.password "$RCONPASS" \
        +server.maxplayers "$PLAYERLIMIT" \
        +server.hostname "$SERVER_HOSTNAME" \
        +server.identity "$MODFOLDER" \
        +server.worldsize "$MAPSIZE" \
        +server.seed "$MAPSEED" \
        +server.saveinterval 180 \
        +app.port "$RUSTPLUSPORT" \
        +app.listenip "$IP" \
        +app.publicip "$IP" \
        +server.secure "true" \
        +server.tickrate "30" \
        +fps.limit "100" \
        +server.pve "false" \
        +chat.enabled "True" \
        +chat.globalchat "True" \
        +server.idlekickmode "1" \
        +server.idlekick "0" \
        +server.idlekickadmins "0" \
        +decay.scale "0.2" \
        +xmas.enabled "0" \
        +decay.upkeep "true" \
        +nav_disable "false" \
        +server.encryption "2" \
        +server.tags "$TAGS" \
        +global.moderatorid "$MODERATORID" \
        +global.ownerid "$OWNERID" \
        +server.description "$DESCRIPTION" \
        +server.level "$MAPLEVEL" \
        +server.headerimage "$HEADERIMAGE" \
        +server.url "$SERVER_URL" \
        +server.gamemode "$SERVER_GAMEMODE" \
        +server.motd "$SERVER_MOTD" \
        +server.writecfg
    if [ $PERFORM_BACKUPS -eq 1 ]; then
        make_backup
    fi
}

echo "Script started at $(date)"
if [[ -z $SERVER_LEVELURL ]]; then
    update_rust_staging
    update_oxide
    run_rust_standard_map
else
    update_rust_staging
    update_oxide
    run_rust_custom_map
fi
