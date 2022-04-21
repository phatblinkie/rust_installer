# rust_installer
simple tool to create a rust server on linux, centos or ubuntu. 

To install, become root user in your linux os, centos or ubuntu should both work

run the following command as root

wget -q -O - https://raw.githubusercontent.com/phatblinkie/rust_installer/main/install_rust.sh | bash

This installer will do the following operations
* install needed libs using yum or apt for steamcmd, and install steamcmd
* Create user named rust (no password, not hackable, just an account to run the service as, you can set a pw later if you like)
* install the service (service runs starter script, which does the following)
  * updates oxide
  * runs rust command
  * after rust exits (likely from your timed command daily telling rust to stop so it can clear its entity leaks), it will make a -backup of the mod folder from the config
* install the scripts and systemd services to run rust, update oxide, update rust
* reload systemctl daemon
* sudo to user rust and install rust for you. 


**IMPORTANT --->>>> edit /etc/rust-settings.conf**

after editing this file you can start your server with
- **systemctl start rust**

you can see the status with 
- **systemctl status rust**

you can watch the log files with 
- **journalctl -f -u rust**

and you can restart or stop with
- **systemctl restart rust**
- **systemctl stop rust**

to set the service to start up at boot time run the command
- **systemctl enable rust**

to update oxide manually run the commands
- **systemctl stop rust**
then
- **systemctl start update-oxide**

to update rust manually run the commands
- **systemctl stop rust**
then
- **systemctl start update-rust**

be sure to star the repo, to show your support :) happy rusting