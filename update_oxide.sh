#!/bin/bash
if [ "${EUID:-$(id -u)}" -eq 0 ]
then
        echo "Please run as the rust user, not root"
        wall "Please run as the rust user, not root"
        #should not happen when run by systemctl, but they may exec manually too
        exit 1
fi

#check if rust is running, if so warn and exit
systemctl is-active --quiet rust && echo -e "\n\nERROR: Rust Service is running\n\nStop this first to avoid corrupting your installation\n\n HINT: systemctl stop rust" && exit 1

echo "Updating Oxide"
wall "Updating Oxide"
cd ~/foxxprod/
rm -f oxide.zip
wget -O oxide.zip https://github.com/OxideMod/Oxide.Rust/releases/latest/download/Oxide.Rust-linux.zip
unzip -o oxide.zip
echo "Oxide update completed"
wall "Oxide update completed"
