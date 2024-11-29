#!/bin/bash
. /etc/rust-settings.conf

function update_oxide()
{
cd ~/foxxprod/
rm -f oxide.zip
wget -O oxide.zip https://umod.org/games/rust/download/develop
unzip -o oxide.zip
}

function make_backup()
{
#make backup of the moded dir, no need for backup of anything else really
 cd ~/foxxprod/
 mkdir -p ~/backups/ 2>&1 >/dev/null
 rsync -avh --progress server ~/backups/`date  +'%B-%d_%H%M%p'`/
 rsync -avh --progress oxide ~/backups/`date  +'%B-%d_%H%M%p'`/
 clear
 #delete old backups older then X days(first run ensures dir is empty, 2nd deletes empty dirs)
# find ~/backups/ -type f -mtime +$DAYS_OF_BACKUPS -delete
# find ~/backups/ -type d -mtime +$DAYS_OF_BACKUPS -delete
}

function run_rust()
{
mkdir -p ~/foxxprod 2>&1 >/dev/null
cd ~/foxxprod/



echo starting rust server
#update oxide each startup
update_oxide
mkdir -p ~/foxxprod/server/jan1/cfg
echo -e "$SERVERAUTO_CFG" > ~/foxxprod/server/jan1/cfg/server.cfg
echo -e "$USERS_CFG" > ~/foxxprod/server/jan1/cfg/users.cfg
#$CMDTORUN $RUSTCMD
./RustDedicated -batchmode -nographics \
+server.ip "$IP" \
+server.port "$GAMEPORT" \
+server.queryport "$QUERYPORT" \
+rcon.ip "$IP" \
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

#+server.levelurl "$SERVER_LEVELURL" \


#when this exits, make a backup
if [ $PERFORM_BACKUPS -eq 1 ]
then
make_backup
fi
}

#this function will update oxide, start the server, and if it exits, make a dated backup of the mod folder

run_rust
