#!/bin/bash
if [ "$UID" -eq "0" ]
then
        echo "do not run as root or with sudo, instead it will ask your sudo pw as needed"
	exit 1
fi
script_version="1.0.2"
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
    if [ -d ~/Steam ]; then
        echo -e "Detected existing steam install, removing...\n"
        rm -rf ~/Steam
    fi
    mkdir -p ~/Steam
    cd ~/Steam
    # Clean up unwanted trash
    rm -rf /tmp/dumps
    # Download and unpack steamcmd
    STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
    STEAMCMD_LOCAL="/path/to/local/steamcmd_linux.tar.gz" # Update for disconnected env
    if [ -f "$STEAMCMD_LOCAL" ]; then
        echo "Using local SteamCMD file: $STEAMCMD_LOCAL"
        tar zxvf "$STEAMCMD_LOCAL" || { echo -e "\nERROR: Failed to extract SteamCMD.\n"; cd $OLDPWD; return 1; }
    else
        if ! curl -sqL "$STEAMCMD_URL" | tar zxvf -; then
            echo -e "\nERROR: Failed to download or extract SteamCMD. Provide $STEAMCMD_LOCAL in disconnected environment.\n"
            return 1
        fi
    fi

    # Set permissions for steam files
    chmod 0755 linux32/* steamcmd.sh

    # Update the steam client
    ./steamcmd.sh +quit

    # Clean up unwanted trash
    rm -rf /tmp/dumps
    cd $OLDPWD
}

function install_requirements() {
    echo -e "\nInstalling pre-requisites\n"
    if [ -f /usr/bin/apt ]; then
        # Ubuntu/Debian
        run_with_sudo add-apt-repository multiverse
        run_with_sudo dpkg --add-architecture i386
        run_with_sudo apt update
        run_with_sudo apt-get install -y lib32gcc-s1 rsync unzip wget curl dbus-user-session
    elif [ -f /usr/bin/dnf ]; then
        # RHEL/CentOS/Fedora
        run_with_sudo dnf install -y glibc.i686 rsync unzip wget libgcc.i686 curl
    else
        echo -e "\nERROR: Unable to find 'apt' or 'dnf'. Unsupported OS?\n"
        exit 1
    fi
}


function get_sudo_password() {
    # Clear any existing sudo credentials
    sudo -k

    echo "===================================================="
    echo " Rust Install Tool - Ver. $script_version"
    echo "===================================================="
    echo "This operation requires root privileges."

    # Loop until we get a valid sudo password
    while true; do
        echo "Please enter your sudo password to proceed:"
        read -r -s SUDO_PASSWORD < /dev/tty

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
    # Use the verified password, preserve errors for debugging
    echo -e "$SUDO_PASSWORD\n" | sudo -S "$@"
}

function configure_firewall() {
    echo -e "\n[ROOT] Firewall Configuration..."

    # Define configuration files
    MAIN_CONFIG="$HOME/rust_main/rust-main-settings.conf"
    STAGING_CONFIG="$HOME/rust_staging/rust-staging-settings.conf"

    # Function to read port from config file
    read_port() {
        local config_file="$1"
        local var_name="$2"
        if [ -f "$config_file" ]; then
            source "$config_file"
            eval echo "\$$var_name"
        else
            echo ""
        fi
    }

    # Read ports from both config files
    declare -A PORTS
    for config in "$MAIN_CONFIG" "$STAGING_CONFIG"; do
        for var in GAMEPORT RUSTPLUSPORT QUERYPORT RCONPORT; do
            port=$(read_port "$config" "$var")
            if [ -n "$port" ] && [[ "$port" =~ ^[0-9]+$ ]]; then
                # Assign protocols: UDP for GAMEPORT and QUERYPORT, TCP for RCONPORT, TCP and UDP for RUSTPLUSPORT
                if [[ "$var" == "GAMEPORT" || "$var" == "QUERYPORT" ]]; then
                    PORTS["${config##*/}_${var}_udp"]="${port}/udp"
                elif [[ "$var" == "RCONPORT" ]]; then
                    PORTS["${config##*/}_${var}_tcp"]="${port}/tcp"
                else
                    # Split RUSTPLUSPORT into separate TCP and UDP entries
                    PORTS["${config##*/}_${var}_tcp"]="${port}/tcp"
                    PORTS["${config##*/}_${var}_udp"]="${port}/udp"
                fi
            fi
        done
    done

    if [ ${#PORTS[@]} -eq 0 ]; then
        echo "Warning: No valid ports found in $MAIN_CONFIG or $STAGING_CONFIG. Skipping firewall configuration."
        return 0
    fi

    # Track errors for final reporting
    local errors=()

    if command -v ufw >/dev/null 2>&1; then
        # Ubuntu (ufw)
        echo "Detected ufw, configuring firewall..."
        if ! run_with_sudo ufw status | grep -q "Status: active"; then
            echo "Enabling ufw (force enable to avoid prompt)..."
            echo "Running: ufw --force enable"
            if ! run_with_sudo ufw --force enable; then
                errors+=("Failed to enable ufw")
            fi
        fi

        for service in "${!PORTS[@]}"; do
            port=${PORTS[$service]}
            echo "Checking port $port for $service..."
            if ! run_with_sudo ufw status | grep -q "$port"; then
                echo "Opening port $port for $service..."
                echo "Running: ufw allow $port"
                if ! run_with_sudo ufw allow "$port"; then
                    errors+=("Failed to open port $port for $service")
                else
                    echo "Successfully opened port $port for $service"
                fi
            else
                echo "Port $port for $service already open, skipping..."
            fi
        done

    elif command -v firewall-cmd >/dev/null 2>&1; then
        # RHEL/CentOS/Fedora (firewalld)
        if ! systemctl is-active --quiet firewalld; then
            echo "Starting firewalld..."
            echo "Running: systemctl start firewalld"
            if ! run_with_sudo systemctl start firewalld; then
                errors+=("Failed to start firewalld")
            fi
        fi

        for service in "${!PORTS[@]}"; do
            port=${PORTS[$service]}
            echo "Checking port $port for $service..."
            if ! run_with_sudo firewall-cmd --query-port="$port" | grep -q "yes"; then
                echo "Opening port $port for $service..."
                echo "Running: firewall-cmd --permanent --add-port=$port"
                if ! run_with_sudo firewall-cmd --permanent --add-port="$port"; then
                    errors+=("Failed to open port $port for $service")
                else
                    echo "Successfully opened port $port for $service"
                fi
            else
                echo "Port $port for $service already open, skipping..."
            fi
        done

        if [ ${#errors[@]} -eq 0 ]; then
            echo "Reloading firewalld..."
            echo "Running: firewall-cmd --reload"
            if ! run_with_sudo firewall-cmd --reload; then
                errors+=("Failed to reload firewalld")
            fi
        fi

    else
        echo "Warning: Neither ufw nor firewalld is installed. Skipping firewall configuration."
        return 0
    fi

    # Report any errors
    if [ ${#errors[@]} -gt 0 ]; then
        echo -e "\nFirewall configuration completed with errors:"
        for error in "${errors[@]}"; do
            echo "  - $error"
        done
        return 1
    else
        echo "Firewall configuration completed successfully!"
        return 0
    fi
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
    return 0
}

function install_rust() {
    # Check if rust is running, if so warn and exit
    systemctl --user is-active --quiet rust-main && echo -e "\n\nERROR: Rust Service is running\n\nStop this first to avoid corrupting your installation\n\n HINT: systemctl stop rust-main" && return 1

    echo -e "\nInstalling or updating Rust - main branch\n"
    if ! ~/Steam/steamcmd.sh +force_install_dir ~/rust_main/ +login anonymous +app_update 258550 validate +exit; then
        echo -e "\nERROR: Failed to install/update Rust. Check SteamCMD or network.\n"
        return 1
    fi

    # Create the systemd files for the user, reload the daemon
    mkdir -p ~/.config/systemd/user 2>/dev/null

    #install service file
    RUST_SERVICE_URL="https://raw.githubusercontent.com/phatblinkie/rust_installer/main/servicefiles/rust-main.service"
    RUST_SERVICE_LOCAL="./servicefiles/rust-main.service" # Update for disconnected env
    if [ -f "$RUST_SERVICE_LOCAL" ]; then
        echo "Using local rust-main.service: $RUST_SERVICE_LOCAL"
        cp "$RUST_SERVICE_LOCAL" ~/.config/systemd/user/rust-main.service
        #fix the path to the local user
        if ! sed -i  "s#HOMEPATH#$HOME#g" ~/.config/systemd/user/rust-main.service; then
            echo -e "\nERROR: file ~/.config/systemd/user/rust-main.service may contain invalid path, unable to modify"
            return 1
        fi
    else 
        if ! wget -q -O ~/.config/systemd/user/rust-main.service "$RUST_SERVICE_URL"; then
            echo -e "\nERROR: Failed to download rust-main.service. Provide $RUST_SERVICE_LOCAL in disconnected environment.\n"
            return 1
        fi
	#fix the path to the local user
	if ! sed -i  "s#HOMEPATH#$HOME#g" ~/.config/systemd/user/rust-main.service; then
	    echo -e "\nERROR: file ~/.config/systemd/user/rust-main.service may contain invalid path, unable to modify"
	    return 1
	fi
    fi

    #install settings file
    if [ -f ~/rust_main/rust-main-settings.conf ]; then
        echo "Found existing configuration file, skipping overwrite"
    else
        RUST_CONFIG_URL="https://raw.githubusercontent.com/phatblinkie/rust_installer/main/configs/rust-main-settings.conf"
        RUST_CONFIG_LOCAL="./configs/rust-main-settings.conf" # Update for disconnected env
        if [ -f "$RUST_CONFIG_LOCAL" ]; then
            echo "Using local rust-main-settings.conf: $RUST_CONFIG_LOCAL"
            cp "$RUST_CONFIG_LOCAL" ~/rust_main/rust-main-settings.conf
        else
            if ! wget -q -O ~/rust_main/rust-main-settings.conf "$RUST_CONFIG_URL"; then
                echo -e "\nERROR: Failed to download rust-main-settings.conf. Provide $RUST_CONFIG_LOCAL in disconnected environment.\n"
                return 1
            fi
	    
            #fix the path to the local user
            if ! sed -i  "s#HOMEPATH#$HOME#g" ~/.config/systemd/user/rust-main.service; then
                echo -e "\nERROR: file ~/.config/systemd/user/rust-main.service may contain invalid path, unable to modify"
                return 1
            fi

        fi
    fi

    #install start script

    RUST_SCRIPT_URL="https://raw.githubusercontent.com/phatblinkie/rust_installer/main/bin/start_rust_main.sh"
    RUST_SCRIPT_LOCAL="./bin/start_rust_main.sh" # Update for disconnected env
    if [ -f "$RUST_SCRIPT_LOCAL" ]; then
        echo "Using local start_rust_main.sh: $RUST_SCRIPT_LOCAL"
        cp "$RUST_SCRIPT_LOCAL" ~/rust_main/start_rust_main.sh
    else
        if ! wget -q -O ~/rust_main/start_rust_main.sh "$RUST_SCRIPT_URL"; then
            echo -e "\nERROR: Failed to download start_rust_main.sh. Provide $RUST_SCRIPT_LOCAL in disconnected environment.\n"
            return 1
        fi
    fi
    chmod 0755 ~/rust_main/start_rust_main.sh
    # Set environment variables for systemd user session
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
    export DBUS_SESSION_BUS_ADDRESS=unix:path=${XDG_RUNTIME_DIR}/bus


    #istall rustedit.dll
    echo installing rustedit.dll
    curl -o ~/rust_main/RustDedicated_Data/Managed/Oxide.Ext.RustEdit.dll "https://github.com/k1lly0u/Oxide.Ext.RustEdit/raw/refs/heads/master/Oxide.Ext.RustEdit.dll"

    #install Discord dlls
    echo installing discord extension
    curl -o ~/rust_main/RustDedicated_Data/Managed/Oxide.Ext.Discord.dll "https://umod.org/extensions/discord/download"

    #fix fucking steamcmd being a pos
    mkdir -p  ~/.steam/sdk64/
    ln -s ~/rust_main/RustDedicated_Data/Plugins/x86_64/steamclient.so ~/.steam/sdk64/steamclient.so

    # Reload daemon
    systemctl --user daemon-reload
    # Enable linger mode
    loginctl enable-linger $USER

    # Ensure systemd user instance is running
    if ! pgrep -u "$USER" -f "systemd --user" >/dev/null; then
        echo "Starting systemd user instance..."
        /lib/systemd/systemd --user &
        sleep 1 # Give it a moment to initialize
    fi

    # Prompt user to enable the service on boot
    echo -e "\nDo you want the rust-main service to start automatically on boot? (y/n)"
    read -r response < /dev/tty
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Enabling rust-main service to start on boot..."
        if systemctl --user enable rust-main; then
            echo "Successfully enabled rust-main service."
        else
            echo "ERROR: Failed to enable rust-main service. Ensure dbus-user-session is installed and the user session is properly initialized."
            echo "Try running: sudo apt-get install dbus-user-session"
            echo "And ensure XDG_RUNTIME_DIR and DBUS_SESSION_BUS_ADDRESS are set."
        fi
    else
        echo "rust-main service will not start automatically on boot."
    fi

    echo -e "\nYou can manage the service with the following commands\n"
    echo -e "systemctl --user start|status|stop rust-main"
    echo
    echo -e "To see logs in real time, use journalctl --user -f -u rust-main"
}

function install_rust_staging() {
    # Check if rust is running, if so warn and exit
    systemctl --user is-active --quiet rust-staging && echo -e "\n\nERROR: Rust Staging Service is running\n\nStop this first to avoid corrupting your installation\n\n HINT: systemctl stop rust-staging" && return 1

    echo -e "\nInstalling or updating Rust - STAGING branch\n"
    if ! ~/Steam/steamcmd.sh +force_install_dir ~/rust_staging/ +login anonymous +app_update 258550 -beta staging validate +exit; then
        echo -e "\nERROR: Failed to install/update Rust staging branch. Check SteamCMD or network.\n"
        return 1
    fi

    # Create the systemd files for the user, reload the daemon
    mkdir -p ~/.config/systemd/user 2>/dev/null

    #install service file
    RUST_SERVICE_URL="https://raw.githubusercontent.com/phatblinkie/rust_installer/main/servicefiles/rust-staging.service"
    RUST_SERVICE_LOCAL="./servicefiles/rust-staging.service" # Update for disconnected env
    if [ -f "$RUST_SERVICE_LOCAL" ]; then
        echo "Using local rust-staging.service: $RUST_SERVICE_LOCAL"
        cp "$RUST_SERVICE_LOCAL" ~/.config/systemd/user/rust-staging.service
        #fix the path to the local user
        if ! sed -i  "s#HOMEPATH#$HOME#g" ~/.config/systemd/user/rust-staging.service; then
            echo -e "\nERROR: file ~/.config/systemd/user/rust-staging.service may contain invalid path, unable to modify"
            return 1
        fi
    else
        if ! wget -q -O ~/.config/systemd/user/rust-staging.service "$RUST_SERVICE_URL"; then
            echo -e "\nERROR: Failed to download rust-staging.service. Provide $RUST_SERVICE_LOCAL in disconnected environment.\n"
            return 1
        fi
        #fix the path to the local user
        if ! sed -i  "s#HOMEPATH#$HOME#g" ~/.config/systemd/user/rust-staging.service; then
            echo -e "\nERROR: file ~/.config/systemd/user/rust-staging.service may contain invalid path, unable to modify"
            return 1
        fi
    fi

    #install settings file
    if [ -f ~/rust_staging/rust-staging-settings.conf ]; then
        echo "Found existing configuration file, skipping overwrite"
    else
        RUST_CONFIG_URL="https://raw.githubusercontent.com/phatblinkie/rust_installer/main/configs/rust-staging-settings.conf"
        RUST_CONFIG_LOCAL="./configs/rust-staging-settings.conf" # Update for disconnected env
        if [ -f "$RUST_CONFIG_LOCAL" ]; then
            echo "Using local rust-staging-settings.conf: $RUST_CONFIG_LOCAL"
            cp "$RUST_CONFIG_LOCAL" ~/rust_staging/rust-staging-settings.conf
        else
            if ! wget -q -O ~/rust_staging/rust-staging-settings.conf "$RUST_CONFIG_URL"; then
                echo -e "\nERROR: Failed to download rust-staging-settings.conf. Provide $RUST_CONFIG_LOCAL in disconnected environment.\n"
                return 1
            fi

            #fix the path to the local user
            if ! sed -i  "s#HOMEPATH#$HOME#g" ~/.config/systemd/user/rust-staging.service; then
                echo -e "\nERROR: file ~/.config/systemd/user/rust-staging.service may contain invalid path, unable to modify"
                return 1
            fi

        fi
    fi
    #install start script

    RUST_SCRIPT_URL="https://raw.githubusercontent.com/phatblinkie/rust_installer/main/bin/start_rust_staging.sh"
    RUST_SCRIPT_LOCAL="./bin/start_rust_staging.sh" # Update for disconnected env
    if [ -f "$RUST_SCRIPT_LOCAL" ]; then
        echo "Using local start_rust_staging.sh: $RUST_SCRIPT_LOCAL"
        cp "$RUST_SCRIPT_LOCAL" ~/rust_staging/start_rust_staging.sh
    else
        if ! wget -q -O ~/rust_staging/start_rust_staging.sh "$RUST_SCRIPT_URL"; then
            echo -e "\nERROR: Failed to download start_rust_staging.sh. Provide $RUST_SCRIPT_LOCAL in disconnected environment.\n"
            return 1
        fi
    fi
    chmod 0755 ~/rust_staging/start_rust_staging.sh
    # Set environment variables for systemd user session
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
    export DBUS_SESSION_BUS_ADDRESS=unix:path=${XDG_RUNTIME_DIR}/bus


    #istall rustedit.dll
    echo installing rustedit.dll
    curl -o ~/rust_staging/RustDedicated_Data/Managed/Oxide.Ext.RustEdit.dll "https://github.com/k1lly0u/Oxide.Ext.RustEdit/raw/refs/heads/master/Oxide.Ext.RustEdit.dll"

    #install Discord dlls
    echo installing discord extension
    curl -o ~/rust_staging/RustDedicated_Data/Managed/Oxide.Ext.Discord.dll "https://umod.org/extensions/discord/download"

    #fix fucking steamcmd being a pos
    mkdir -p  ~/.steam/sdk64/
    ln -s ~/rust_staging/RustDedicated_Data/Plugins/x86_64/steamclient.so ~/.steam/sdk64/steamclient.so

    # Reload daemon
    systemctl --user daemon-reload
    # Enable linger mode
    loginctl enable-linger $USER

    # Ensure systemd user instance is running
    if ! pgrep -u "$USER" -f "systemd --user" >/dev/null; then
        echo "Starting systemd user instance..."
        /lib/systemd/systemd --user &
        sleep 1 # Give it a moment to initialize
    fi

    # Prompt user to enable the service on boot
    echo -e "\nDo you want the rust-staging service to start automatically on boot? (y/n)"
    read -r response < /dev/tty
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "Enabling rust-staging service to start on boot..."
        if systemctl --user enable rust-staging; then
            echo "Successfully enabled rust-staging service."
        else
            echo "ERROR: Failed to enable rust-staging service. Ensure dbus-user-session is installed and the user session is properly initialized."
            echo "Try running: sudo apt-get install dbus-user-session"
            echo "And ensure XDG_RUNTIME_DIR and DBUS_SESSION_BUS_ADDRESS are set."
        fi
    else
        echo "rust-staging service will not start automatically on boot."
    fi

    echo -e "\nYou can manage the service with the following commands\n"
    echo -e "systemctl --user start|status|stop rust-staging"
    echo
    echo -e "To see logs in real time, use journalctl --user -f -u rust-staging"

}


function install_oxide() {
    # Check if rust is running, if so warn and exit
    systemctl --user is-active --quiet rust-main && echo -e "\n\nERROR: Rust Service is running\n\nStop this first to avoid corrupting your installation\n\n HINT: systemctl stop rust-main" && return 1

    echo -e "\nUpdating Oxide\n"
    cd ~/rust_main/
    rm -f oxide.zip
    OXIDE_URL="https://github.com/OxideMod/Oxide.Rust/releases/latest/download/Oxide.Rust-linux.zip"
    OXIDE_LOCAL="/path/to/local/Oxide.Rust-linux.zip" # Update for disconnected env
    if [ -f "$OXIDE_LOCAL" ]; then
        echo "Using local Oxide file: $OXIDE_LOCAL"
        cp "$OXIDE_LOCAL" oxide.zip
    else
        if ! wget -O oxide.zip "$OXIDE_URL"; then
            echo -e "\nERROR: Failed to download Oxide. Provide $OXIDE_LOCAL in disconnected environment.\n"
            cd $OLDPWD
            return 1
        fi
    fi
    unzip -o oxide.zip
    echo "Oxide update completed"
    cd $OLDPWD
}

function install_oxide_staging() {
    # Check if rust is running, if so warn and exit
    systemctl --user is-active --quiet rust-staging && echo -e "\n\nERROR: Rust Service is running\n\nStop this first to avoid corrupting your installation\n\n HINT: systemctl stop rust-staging" && return 1

    echo -e "\nUpdating STAGING Oxide\n"
    cd ~/rust_staging/
    rm -f oxide.zip
    OXIDE_STAGING_URL="https://downloads.oxidemod.com/artifacts/Oxide.Rust/staging/Oxide.Rust-linux.zip"
    OXIDE_STAGING_LOCAL="/path/to/local/Oxide.Rust-linux-staging.zip" # Update for disconnected env
    if [ -f "$OXIDE_STAGING_LOCAL" ]; then
        echo "Using local Oxide staging file: $OXIDE_STAGING_LOCAL"
        cp "$OXIDE_STAGING_LOCAL" oxide.zip
    else
        if ! wget -O oxide.zip "$OXIDE_STAGING_URL"; then
            echo -e "\nERROR: Failed to download Oxide staging. Provide $OXIDE_STAGING_LOCAL in disconnected environment.\n"
            cd $OLDPWD
            return 1
        fi
    fi
    unzip -o oxide.zip
    echo "Oxide staging update completed"
    cd $OLDPWD
}

show_menu() {
    clear
    echo "==========================================================================="
    echo " Rust Install Tool - Ver. $script_version"
    echo "==========================================================================="
    echo " 1. Install pre-requisites"
    echo " 2. Download or Re-Install SteamCMD"
    echo " 3. Install/update Rust"
    echo " 4. Install/update oxide"
    echo " 5. Install/update Rust Staging Branch"
    echo " 6. Install/update oxide on Staging Branch"
    echo " 7. Configure firewall - uses ports in the config files. edit those first"
    echo " 8. Start main rust server"
    echo " 9. Stop main rust server"
    echo ""
    echo " 0. Exit"
    echo "============================================================================"
}

# ---------- Main Execution ----------

# Interactive menu mode
while true; do
    show_menu
    read -p "Enter your choice (0-7): " choice < /dev/tty

    case $choice in
        1)
            get_sudo_password
            install_requirements
            ;;
        2) install_steam ;;
        3) install_rust ;;
        4) install_oxide ;;
        5) install_rust_staging ;;
        6) install_oxide_staging ;;
        7)
            get_sudo_password
            configure_firewall
            ;;
	8)  echo "Starting rust-main" && systemctl --user start rust-main ;;
	9)  echo "Stopping rust-main" && systemctl --user stop rust-main ;;
        0)
            echo "Exiting. Have a nice day!"
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac

    read -p "Press [Enter] to continue..." < /dev/tty
done
