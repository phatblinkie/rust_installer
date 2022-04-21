#!/bin/bash
if [ "${EUID:-$(id -u)}" -eq 0 ]
then
        echo "Please run as the rust user, not root"
        #should not happen when run by systemctl, but they may exec manually too
        exit 1
fi

#check if rust is running, if so warn and exit
systemctl is-active --quiet rust && echo -e "\n\nERROR: Rust Service is running\n\nStop this first to avoid corrupting your installation\n\n HINT: systemctl stop rust" && exit 1

#ok not running, now to update. for the ubuntu installs, they use the repository package, and have a different path to the binaries
#depending which we find, use it instead of guessing the path
if (test -f /usr/local/bin/steamcmd.sh)
then
    su - rust -c "/usr/local/bin/steamcmd.sh +force_install_dir ~/rustserver/ +login anonymous +app_update 258550 validate +exit"
elif (test -f /usr/games/steamcmd)
then
    su - rust -c "/usr/games/steamcmd +force_install_dir ~/rustserver/ +login anonymous +app_update 258550 validate +exit"
else
    echo "ERROR: unable to find steamcmd at /usr/local/bin/steamcmd.sh or /usr/games/steamcmd"
    exit 1
fi
echo "Game has been updated successfully"
exit 0
