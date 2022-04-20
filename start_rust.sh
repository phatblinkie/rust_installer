#!/bin/bash
IP=20.100.100.20
GAMEPORT=28015
RUSTPLUSPORT=28292
RCONPORT=28016
RCONPASS="testpass"
#to set the first admin account without having to use rcon first
moderatorid=76561197972406742
#foldername holding your mods, using a month makes it simple to keep versions separated each month
MODFOLDER="march"
#map stuff
MAPSIZE=4500
MAPSEED=621866835
#change to map url and name if not procedural
MAPLEVEL="Procedural Map"
TAGS="biweekly,pve"
#be careful on description punctions, do not use chars that break out of the '' use \n for line breaks
DESCRIPTION="Tired of getting raided by zergs, or banned for admin abuse? \nErosion PVE helps you out! \n\nWe are a growing and active community where you can come to chill. \nBuild as much as you want and even raid! \n\nOur unique plugin allows players to raid npc bases on a pve server! \n\n- Backpacks \n- BGrade \n- Bots at monuments, PVP Zones, Bots at NPC bases \n- Furnace Splitter \n- Kits \n- NTeleportation \n- Furnace upgrader \n- Remover Tool \n- Server Rewards  \n- Buyable attack Heli \n- Personal Vehicles \n- Increased Stack Sizes \n- Trade \n- Many more "
#used in server browser description
HEADERIMAGE="https://i.imgur.com/bkBDyUp.png"
#used in the server website button, most point this to discord join link
SERVER_URL="https://discord.gg/HWSDzGSCqj"
#the main hostname of server
SERVER_HOSTNAME="[US] Erosion PvE - Raidable NPC Bases - Private Raids"





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
