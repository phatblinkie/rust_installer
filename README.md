# rust_installer
simple tool to create a rust server on linux, centos or ubuntu. 

To install, become root user in your linux os, centos or ubuntu should both work

run the following command as root

wget -q -O - https://raw.githubusercontent.com/phatblinkie/rust_installer/main/install_rust.sh | bash

This installer will do the following operations
* install needed libs using apt for steamcmd, and install steamcmd
* install the rust server or rust staging server
  * updates oxide for either
  * installs systemd --user service files for rust and or rust staging branch
  * puts configuration files for you to edit inside rust_main/ or rust_staging/
  * after rust exits (likely from your timed command daily telling rust to stop so it can clear its entity leaks), it will make a -backup of the mod folder from the config
* sudo to user rust and install rust for you. 


**IMPORTANT --->>>> edit ~/rust_main/rust-main/settings.conf**

After editing this file you can start your server with
- **systemctl --user start rust-main*
- **systemctl --user start rust-staging*


you can see the status with 
- **systemctl --user status rust-main*
- **systemctl --user status rust-staging*

You can watch the log files with 
- **journalctl -f -u rust-main*
- **journalctl -f -u rust-staging*


And you can restart or stop with
- **systemctl --user restart rust-main**
- **systemctl --user stop rust-main**

To set the service to start up at boot time run the command
- **systemctl --user enable rust-main**
- **systemctl --user enable rust-staging**


To update oxide you can run the installer again, and pick the choice to update oxid
This also applies the other options like updating the rust server as well

Be sure to star the repo, to show your support :) happy rusting
