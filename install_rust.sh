#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root user"
  exit
fi


#update linux install
#yum update -y

#install needed libs
if ( test -f /usr/bin/yum ) ; then yum install -y glibc.i686 libstdc++.i686 rsync unzip wget; fi
if ( test -f /usr/bin/apt ) ; then apt-get install -y glibc.i686 libstdc++.i686 rsync unzip wget; fi

mkdir -p steaminstaller
cd steaminstaller
#download and unpack steamcmd
curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

#this updates the steam client
./steamcmd.sh

#move steamfiles to /usr/local/bin so its in the right spot for users bin
mv * /usr/local/bin/

#clean up unwanted trash
rm -rf /tmp/dumps
cd ..
rm -rf steaminstaller

#add the intended user directory
getent passwd rust > /dev/null
if [ $? -ne 0 ]; then
useradd rust
echo created username rust for service
fi

#change to the user for the rust install (not strictly needed but if you got the disk space why not)
sudo su - rust

#install the linux rust server files (vanilla, public branch), anon login, and force to users home/rustserver/ dir (+exit gets out of steamcmd, leave it there)
/usr/local.bin/steamcmd.sh +force_install_dir ~/rustserver/ +login anonymous +app_update 258550 validate +exit

#will take a few minutes to download
# the service file will update oxide when run.

wget --output-file=/usr/lib/systemd/system/rust.service https://raw.githubusercontent.com/phatblinkie/rust_installer/main/rust.service
wget --output-file=/usr/local/bin/start_rust.sh https://raw.githubusercontent.com/phatblinkie/rust_installer/main/start_rust.sh

chmod 0755 /usr/local/bin/start_rust.sh
systemctl daemon-reload

clear
echo "Rust installed, Rust service installed, Rust starter script installed"
echo "Before starting rust with the command"
echo ""
echo "systemctl start rust"
echo ""
echo "you edit and set the variables up in the top of the file /usr/local/bin/start_rust.sh"