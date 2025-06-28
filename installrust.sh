#!/bin/bash

script_version="1.0.0"
# ---------- Initial Setup ----------

# Clear the sudo password variable on exit
function cleanup() {
    unset SUDO_PASSWORD
    # Clear sudo cache to ensure fresh prompt next time
    sudo -k
}
trap cleanup EXIT


function install_steam() {

    echo -e "\nInstalling SteamCMD\n"
    if [ -d Steam ]
    then
	    echo -e "Detected existing steam install, removing...\n"
	    rm -rf Steam
    fi
    mkdir -p Steam
    cd Steam
    #clean up unwanted trash
    rm -rf /tmp/dumps
    #download and unpack steamcmd
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
    #this updates the steam client
    ./steamcmd.sh +quit

    #move steamfiles to /usr/local/bin so its in the right spot for users bin
    chmod 0755 linux32/* steamcmd.sh


    #clean up unwanted trash
    rm -rf /tmp/dumps
    cd ..
    #rm -rf steaminstaller
}

function install_requirements() {
   echo -e "\n Installing pre-requisates\n"
   get_sudo_password
   if [ -f /usr/bin/apt ]
   then
     run_with_sudo add-apt-repository multiverse
     run_with_sudo dpkg --add-architecture i386
     run_with_sudo apt update
     run_with_sudo apt-get install -y lib32gcc-s1 rsync unzip wget
   else
     echo -e "\nERROR: unable to find 'apt' wrong os?\n"
   fi
}

# ---------- Improved Sudo Password Handling ----------

function get_sudo_password() {
    # Clear any existing sudo credentials
    sudo -k

    echo "===================================================="
    echo " Monitoring Stack Deployment Tool - Ver. $script_version"
    echo "===================================================="
    echo "This script requires root privileges for some operations."

    # Loop until we get a valid sudo password
    while true; do
        echo "Please enter your sudo password to proceed:"
        read -r -s SUDO_PASSWORD

        # Verify the password works by trying to list root directory
        echo
        echo -n "Verifying sudo access... "
        if echo "$SUDO_PASSWORD" | sudo -S ls /root >/dev/null 2>&1; then
            echo "OK"
            break
        else
            echo "FAILED"
            echo "Incorrect sudo password. Please try again."
            unset SUDO_PASSWORD
        fi
    done

    # Export the verified password
    export SUDO_PASSWORD
    echo
}

function run_with_sudo() {
    # Use the verified password with proper newline handling
    echo -e "$SUDO_PASSWORD\n" | sudo -S "$@" 2>/dev/null
}

function configure_firewall() {
    echo -e "\n[ROOT] Firewall Configuration..."

    if ! command -v firewall-cmd &> /dev/null; then
        echo "Warning: firewalld is not installed. Skipping firewall configuration."
        return 0
    fi

    if ! systemctl is-active --quiet firewalld; then
        echo "Starting firewalld..."
        run_with_sudo systemctl start firewalld
    fi

    declare -A PORTS=(
        ["HTTP"]="80/tcp"
        ["HTTPs"]="443/tcp"
        ["Grafana"]="3000/tcp"
        ["Mimir"]="3100/tcp"
        ["Loki"]="9009/tcp"
    )


    for service in "${!PORTS[@]}"; do
        port=${PORTS[$service]}
        if ! run_with_sudo firewall-cmd --query-port="$port" | grep -q "yes"; then
            echo "Opening port $port for $service..."
            run_with_sudo firewall-cmd --permanent --add-port="$port"
            check_success "Failed to open port $port" || return 1
        fi
    done

    echo "Adding NFS service"
    run_with_sudo firewall-cmd --permanent --now --add-service="nfs"


    echo "Reloading firewalld..."
    run_with_sudo firewall-cmd --reload
    check_success "Failed to reload firewalld" || return 1

    echo "Firewall configuration completed successfully!"
}


function check_permission() {
    local file="$1"
    local expected_perm="$2"
    local actual_perm=$(stat -c "%a" "$file" 2>/dev/null)

    if [[ "$actual_perm" != "$expected_perm" ]]; then
        echo "[FAIL] $file has permissions $actual_perm (expected $expected_perm)"
        echo "Please run the system configuration first or manually fix with:"
        echo "sudo chmod $expected_perm $file"
        return 1
    fi
    return 0
}

function check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1" >&2
        return 1
    fi
}

function install_rust() {
	echo -e "\nInstalling or updating Rust - main branch\n"
	./Steam/steamcmd.sh +force_install_dir ~/rust_main/ +login anonymous +app_update 258550 validate +exit

	#create the systemd files for the user, reload the daemon
	mkdir -p ~/.config/systemd/user 2>/dev/null
	wget -q --output-document=~/.config/systemd/user/rust-main.service https://raw.githubusercontent.com/phatblinkie/rust_installer/main/rust-main.service
	#reload daemon
	systemctl --user daemon-reload
	#enable linger mode
	loginctl linger

	echo -e "\n You can manage the service with the following commands\n"
	echo -e "systemctl --user start|status|stop rust-main"
	echo
	echo -e "To see logs in real time, use journalctl -f -u rust-main"
}

function install_rust_staging() {
        echo -e "\nInstalling or updating Rust - STAGING branch\n"
        ./Steam/steamcmd.sh +force_install_dir ~/rust_staging/ +login anonymous +app_update 258550 -beta staging validate +exit

	#create the systemd files for the user, reload the daemon
	mkdir -p ~/.config/systemd/user 2>/dev/null
        wget -q --output-document=~/.config/systemd/user/rust-staging.service https://raw.githubusercontent.com/phatblinkie/rust_installer/main/rust-staging.service
        #reload daemon
        systemctl --user daemon-reload
        #enable linger mode
        loginctl linger

        echo -e "\n You can manage the service with the following commands\n"
        echo -e "systemctl --user start|status|stop rust-staging"
        echo
        echo -e "To see logs in real time, use journalctl -f -u rust-staging"

}

function install_oxide() {
	#check if rust is running, if so warn and exit
	systemctl --user is-active --quiet rust && echo -e "\n\nERROR: Rust Service is running\n\nStop this first to avoid corrupting your installation\n\n HINT: systemctl stop rust" && return 1

	echo -e \n"Updating Oxide\n"
	cd ~/rust_main/
	rm -f oxide.zip
	wget -O oxide.zip https://github.com/OxideMod/Oxide.Rust/releases/latest/download/Oxide.Rust-linux.zip
	unzip -o oxide.zip
	echo "Oxide update completed"
}

function install_oxide_staging() {
	#check if rust is running, if so warn and exit
	systemctl --user is-active --quiet rust-staging && echo -e "\n\nERROR: Rust Service is running\n\nStop this first to avoid corrupting your installation\n\n HINT: systemctl stop rust" && return 1

	echo -e \n"Updating STAGING Oxide\n"
	cd ~/rust_staging/
	rm -f oxide.zip
	wget -O oxide.zip https://downloads.oxidemod.com/artifacts/Oxide.Rust/staging/Oxide.Rust-linux.zip
	unzip -o oxide.zip
	echo "Oxide update completed"
}


show_menu() {
    clear
    echo "===================================================="
    echo " Ubuntu Rust Install Tool - Ver. $script_version"
    echo "===================================================="
    echo " 1. Install pre-requisates"
    echo " 2. Download or Re-Install SteamCMD"
    echo " 3. Install/update Rust"
    echo " 4. Install/update oxide"
    echo " 5. Install/update Rust Staging Branch"
    echo " 6. Install/update oxide on Staging Branch"
    echo " 0. Exit"
    echo "===================================================="
}


# ---------- Main Execution ----------

# Always get sudo password at the very start
#get_sudo_password

# Interactive menu mode
while true; do
    show_menu
    read -p "Enter your choice (0-8): " choice

    case $choice in
        1) install_requirements ;;
        2) install_steam ;;
	3) install_rust ;;
	4) install_oxide ;;
	5) install_rust_staging ;;
	6) install_oxide_staging ;;
        0)
            echo "Exiting. Have a nice day!"
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac

    read -p "Press [Enter] to continue..."
done
