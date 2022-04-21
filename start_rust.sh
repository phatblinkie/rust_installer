#!/bin/bash
#replace with your servers ip address
IP=20.100.100.20
#this is the port the players will connect to reach your game server
GAMEPORT=28015
#this port is used by the rust+ app
RUSTPLUSPORT=28292
#this is your rcon port for remote management
RCONPORT=28016
#this is the password used for remote management, do not use " in it or this will break
RCONPASS="testpass"
#to set the first admin account without having to use rcon first, This is the users steamid
moderatorid=76561197972406742
#foldername holding your mods, using a month makes it simple to keep versions separated each month
#if this does not exist, it will be created at /home/rust/rustserver/server/thisfoldername
#additionally this will get backed up each time the server is stopped at /home/rust/backups/{datedfolder}/{modfoldername}
MODFOLDER="march"
#map stuff
#dont forget, you set this too big, less people can play on your server, they wont even see it.
MAPSIZE=1001
#https://rustmaps.com/  is a great resource for mapsize and seed options
MAPSEED=469
#change to map url and name if not procedural
MAPLEVEL="Procedural Map"
#https://wiki.facepunch.com/rust/server-browser-tags
TAGS="biweekly,pve"
#be careful on description punctions, do not use chars that break out of the '' use \n for line breaks
DESCRIPTION="Replace this with your own Description, use \n for new lines"
#used in server browser description
HEADERIMAGE="https://i.imgur.com/bkBDyUp.png"
#used in the server website button, most point this to discord join link
SERVER_URL="https://discord.gg/HWSDzGSCqj"
#the main hostname of server
SERVER_HOSTNAME="phatblinkie is so nice, make him famous and star his repo"





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

}

function run_rust()
{
cd ~/rustserver/
IFS=''
read -r -d '' RUSTCMD << EOM
+server.ip $IP \
+server.port $GAMEPORT \
+rcon.port $RCONPORT \
+rcon.password "$RCONPASS" \
+rcon.web "1" \
-server.maxplayers "75" \
-server.hostname "$SERVER_HOSTNAME" \
-server.identity "$MODFOLDER" \
-server.worldsize $MAPSIZE \
-server.description "$DESCRIPTION" \
-server.headerimage "$HEADERIMAGE" \
-server.url "$SERVER_URL" \
+server.level "$MAPLEVEL" \
+server.seed "$MAPSEED" \
+server.saveinterval "180" \
+app.port $RUSTPLUSPORT \
+server.secure "true" \
-cheatpunch \
+decay.scale "0.2" \
+xmas.enabled "1" \
+decay.upkeep "true" \
+nav_disable "false" \
+server.encryption "2" \
+server.tags $TAGS \
+global.moderatorid $moderatorid \
+server.writecfg
EOM

CMDTORUN="./RustDedicated"
echo starting rust server
update_oxide
$CMDTORUN $RUSTCMD
make_backup
}

#this will update oxide, start the server, and if it exits, make a dated backup of the mod folder
run_rust
