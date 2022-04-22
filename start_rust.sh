#!/bin/bash
. /etc/rust-settings.conf

function update_oxide()
{
cd ~/rustserver/
rm -f oxide.zip
wget -O oxide.zip https://umod.org/games/rust/download/develop
unzip -o oxide.zip
}

function make_backup()
{
#make backup of the moded dir, no need for backup of anything else really
 cd ~/rustserver/
 mkdir -p ~/backups/ 2>&1 >/dev/null
 rsync -avh --progress server/$MODFOLDER ~/backups/`date  +'%B-%d_%H%M%p'`/
 clear
 #delete old backups older then X days(first run ensures dir is empty, 2nd deletes empty dirs)
 find ~/backups/ -type f -mtime +$DAYS_OF_BACKUPS -delete
 find ~/backups/ -type d -mtime +$DAYS_OF_BACKUPS -delete
}

function run_rust()
{
cd ~/rustserver/



echo starting rust server
#update oxide each startup
update_oxide

#$CMDTORUN $RUSTCMD
./RustDedicated -batchmode -nographics \
-server.ip $IP \
-server.port $GAMEPORT \
-rcon.ip $IP \
-rcon.port $RCONPORT \
-rcon.password $RCONPASS \
-server.maxplayers $PLAYERLIMIT \
-server.hostname "$SERVER_HOSTNAME" \
-server.identity $MODFOLDER \
-server.worldsize $MAPSIZE \
-server.seed $MAPSEED \
-server.saveinterval 180 \
-app.port $RUSTPLUSPORT \
-server.secure true \
-decay.scale 0.2 \
-xmas.enabled 1 \
-decay.upkeep true \
-nav_disable false \
-server.encryption 2 \
-server.tags $TAGS \
+global.moderatorid $MODERATORID \
-server.description "$DESCRIPTION" \
-server.level "$MAPLEVEL" \
-server.headerimage "$HEADERIMAGE" \
-server.url "$SERVER_URL" \
+server.writecfg



#when this exits, make a backup
if [ $PERFORM_BACKUPS -eq 1 ]
then
make_backup
fi
}

#this function will update oxide, start the server, and if it exits, make a dated backup of the mod folder

run_rust
