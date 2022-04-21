#!/bin/bash
#check if rust is running, if so warn and exit
systemctl is-active --quiet rust && echo -e "\n\nERROR: Rust Service is running\n\nStop this first to avoid corrupting your installation\n\n HINT: systemctl stop rust" && exit 1

echo "Updating Oxide"
cd ~/rustserver/
rm -f oxide.zip
wget -O oxide.zip https://umod.org/games/rust/download/develop
unzip -o oxide.zip
echo "Oxide update completed"
