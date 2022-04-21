#!/bin/bash
if [ "${EUID:-$(id -u)}" -ne 0 ]
then
        echo "Please run as root"
        exit
fi


#update linux install
#yum update -y

#install needed libs
if ( test -f /usr/bin/yum )
then
    yum install -y glibc.i686 libstdc++.i686 rsync unzip wget
    mkdir -p steaminstaller
    cd steaminstaller
    #clean up unwanted trash
    rm -rf /tmp/dumps
    #download and unpack steamcmd
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
    #this updates the steam client
    ./steamcmd.sh +quit

    #move steamfiles to /usr/local/bin so its in the right spot for users bin
    mv * /usr/local/bin/
    steamcommand=/usr/local/bin/steamcmd.sh

    #clean up unwanted trash
    rm -rf /tmp/dumps
    cd ..
    rm -rf steaminstaller
fi

if ( test -f /usr/bin/apt )
then
  add-apt-repository multiverse
  dpkg --add-architecture i386
  apt update
  apt-get install -y steamcmd  lib32gcc-s1 rsync unzip wget
  #this updates the steam client
  steamcommand=/usr/games/steamcmd
  $steamcommand +quit
  #clean up unwanted trash
  rm -rf /tmp/dumps
fi




#add the intended user directory
getent passwd rust > /dev/null
if [ $? -ne 0 ]; then
printf "\n################################\nAdding user: rust\n################################\n\n"
useradd rust -s /bin/bash -m

fi

#change to the user for the rust install (not strictly needed but if you got the disk space why not)
#install the linux rust server files (vanilla, public branch), anon login, and force to users home/rustserver/ dir
#(+exit gets out of steamcmd, leave it there)
#clean up unwanted trash from steam
rm -rf /tmp/dumps
printf "\n################################\nInstalling steam as user: rust\n################################\n\n"
su - rust -c "$steamcommand +force_install_dir ~/rustserver/ +login anonymous +app_update 258550 validate +exit"


#will take a few minutes to download
# the service file will update oxide when run.
printf "\n################################\nInstalling Rust service file\n################################\n\n"
wget --output-document=/usr/lib/systemd/system/rust.service https://raw.githubusercontent.com/phatblinkie/rust_installer/main/rust.service

printf "\n################################\nInstalling Rust Startup script\n################################\n\n"
wget --output-document=/usr/local/bin/start_rust.sh https://raw.githubusercontent.com/phatblinkie/rust_installer/main/start_rust.sh

printf "\n################################\nInstalling Oxide updater script\n################################\n\n"
wget --output-document=/usr/local/bin/update_oxide.sh https://raw.githubusercontent.com/phatblinkie/rust_installer/main/update_oxide.sh

printf "\n################################\nInstalling Oxide updater service\n################################\n\n"
wget --output-document=/usr/lib/systemd/system/update-oxide.service https://raw.githubusercontent.com/phatblinkie/rust_installer/main/update-oxide.service

printf "\n################################\nInstalling Rust updater script\n################################\n\n"
wget --output-document=/usr/local/bin/update_rust.sh https://raw.githubusercontent.com/phatblinkie/rust_installer/main/update_rust.sh

printf "\n################################\nInstalling Rust updater service\n################################\n\n"
wget --output-document=/usr/lib/systemd/system/update-rust.service https://raw.githubusercontent.com/phatblinkie/rust_installer/main/update-rust.service



printf "\n################################\nFixing up perms and systemd\n################################\n\n"
chmod 0755 /usr/local/bin/start_rust.sh /usr/local/bin/update_oxide.sh /usr/local/bin/update_rust.sh
systemctl daemon-reload

echo -e "\n\n\n"
echo "Rust installed, Rust service installed, Rust starter script installed"
echo "Before starting rust with the command"
echo ""
echo "systemctl start rust"
echo ""
echo "you edit and set the variables up in the top of the file /usr/local/bin/start_rust.sh"
