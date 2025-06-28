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
    if [ -d Steam ]; then
        echo -e "Detected existing steam install, removing...\n"
        rm -rf Steam
    fi
    mkdir -p Steam
    cd Steam
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
            cd $OLDPWD
            return 1
        fi
    fi
    # Update the steam client
    ./steamcmd.sh +quit

    # Set permissions for steam files
    chmod 0755 linux32/* steamcmd.sh

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
        run_with_sudo apt-get install -y lib32gcc-s1 rsync unzip wget curl
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

    if command -v ufw >/dev/null 2>&1; then
        # Ubuntu (ufw)
        echo "Detected ufw, configuring firewall..."
        if ! run_with_sudo ufw status | grep -q "Status: active"; then
            echo "Enabling ufw (force enable to avoid prompt)..."
            echo "Running: ufw --force enable"
            run_with_sudo ufw --force enable
            check_success "Failed to enable ufw" && return 1
        fi

        for service in "${!PORTS[@]}"; do
            port=${PORTS[$service]}
            echo "Checking port $port for $service..."
            if ! run_with_sudo ufw status | grep -q "$port"; then
                echo "Opening port $port for $service..."
                echo "Running: ufw allow $port"
                run_with_sudo ufw allow "$port"
                check_success "Failed to open port $port" && return 1
            else
                echo "Port $port for $service already open, skipping..."
            fi
        done

        echo "Firewall configuration completed successfully!"

    elif command -v firewall-cmd >/dev/null 2>&1; then
        # RHEL/CentOS/Fedora (firewalld)
        if ! systemctl is-active --quiet firewalld; then
            echo "Starting firewalld..."
            echo "Running: systemctl start firewalld"
            run_with_sudo systemctl start firewalld
            check_success "Failed to start firewalld" && return 1
        fi

        for service in "${!PORTS[@]}"; do
            port=${PORTS[$service]}
            echo "Checking port $port for $service..."
            if ! run_with_sudo firewall-cmd --query-port="$port" | grep -q "yes"; then
                echo "Opening port $port for $service..."
                echo "Running: firewall-cmd --permanent --add-port=$port"
                run_with_sudo firewall-cmd --permanent --add-port="$port"
                check_success "Failed to open port $port" && return 1
            else
                echo "Port $port for $service already open, skipping..."
            fi
        done

        echo "Reloading firewalld..."
        echo "Running: firewall-cmd --reload"
        run_with_sudo firewall-cmd --reload
        check_success "Failed to reload firewalld" && return 1

        echo "Firewall configuration completed successfully!"
    else
        echo "Warning: Neither ufw nor firewalld is installed. Skipping firewall configuration."
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
    echo -e "\nInstalling or updating Rust - main branch\n"
    if ! ./Steam/steamcmd.sh +force_install_dir ~/rust_main/ +login anonymous +app_update 258550 validate +exit; then
        echo -e "\nERROR: Failed to install/update Rust. Check SteamCMD or network.\n"
        return 1
    fi

    # Create the systemd files for the user, reload the daemon
    mkdir -p ~/.config/systemd/user 2>/dev/null
    RUST_SERVICE_URL="https://raw.githubusercontent.com/phatblinkie/rust_installer/main/servicefiles/rust-main.service"
    RUST_SERVICE_LOCAL="/path/to/local/rust-main.service" # Update for disconnected env
    if [ -f "$RUST_SERVICE_LOCAL" ]; then
        echo "Using local rust-main.service: $RUST_SERVICE_LOCAL"
        cp "$RUST_SERVICE_LOCAL" ~/.config/systemd/user/rust-main.service
    else
        if ! wget -q -O ~/.config/systemd/user/rust-main.service "$RUST_SERVICE_URL"; then
            echo -e "\nERROR: Failed to download rust-main.service. Provide $RUST_SERVICE_LOCAL in disconnected environment.\n"
            return 1
        fi
    fi
    if [ -f ~/rust_main/rust-main-settings.conf ]; then
        echo "Found existing configuration file, skipping overwrite"
    else
        RUST_CONFIG_URL="https://raw.githubusercontent.com/phatblinkie/rust_installer/main/configs/rust-main-settings.conf"
        RUST_CONFIG_LOCAL="/path/to/local/rust-main-settings.conf" # Update for disconnected env
        if [ -f "$RUST_CONFIG_LOCAL" ]; then
            echo "Using local rust-main-settings.conf: $RUST_CONFIG_LOCAL"
            cp "$RUST_CONFIG_LOCAL" ~/rust_main/rust-main-settings.conf
        else
            if ! wget -q -O ~/rust_main/rust-main-settings.conf "$RUST_CONFIG_URL"; then
                echo -e "\nERROR: Failed to download rust-main-settings.conf. Provide $RUST_CONFIG_LOCAL in disconnected environment.\n"
                return 1
            fi
        fi
    fi

    RUST_SCRIPT_URL="https://raw.githubusercontent.com/phatblinkie/rust_installer/main/bin/start_rust_main.sh"
    RUST_SCRIPT_LOCAL="/path/to/local/start_rust_main.sh" # Update for disconnected env
    if [ -f "$RUST_SCRIPT_LOCAL" ]; then
        echo "Using local start_rust_main.sh: $RUST_SCRIPT_LOCAL"
        cp "$RUST_SCRIPT_LOCAL" ~/rust_main/start_rust_main.sh
    else
        if ! wget -q -O ~/rust_main/start_rust_main.sh "$RUST_SCRIPT_URL"; then
            echo -e "\nERROR: Failed to download start_rust_main.sh. Provide $RUST_SCRIPT_LOCAL in disconnected environment.\n"
            return 1
        fi
    fi
    sed -i "s/USERNAME/$USER/" ~/.config/systemd/user/rust-main.service
    chmod 0755 ~/rust_main/start_rust_main.sh
    # Reload daemon
    systemctl --user daemon-reload
    # Enable linger mode
    loginctl enable-linger

    echo -e "\n You can manage the service with the following commands\n"
    echo -e "systemctl --user start|status|stop rust-main"
    echo
    echo -e "To see logs in real time, use journalctl -f -u rust-main"
}

function install_rust_staging() {
    echo -e "\nInstalling or updating Rust - STAGING branch\n"
    if ! ./Steam/steamcmd.sh +force_install_dir ~/rust_staging/ +login anonymous +app_update 258550 -beta staging validate +exit; then
        echo -e "\nERROR: Failed to install/update Rust Staging. Check SteamCMD or network.\n"
        return 1
    fi

    # Create the systemd files for the user, reload the daemon
    mkdir -p ~/.config/systemd/user 2>/dev/null
    STAGING_SERVICE_URL="https://raw.githubusercontent.com/phatblinkie/rust_installer/main/servicefiles/rust-staging.service"
    STAGING_SERVICE_LOCAL="/path/to/local/rust-staging.service" # Update for disconnected env
    if [ -f "$STAGING_SERVICE_LOCAL" ]; then
        echo "Using local rust-staging.service: $STAGING_SERVICE_LOCAL"
        cp "$STAGING_SERVICE_LOCAL" ~/.config/systemd/user/rust-staging.service
    else
        if ! wget -q -O ~/.config/systemd/user/rust-staging.service "$STAGING_SERVICE_URL"; then
            echo -e "\nERROR: Failed to download rust-staging.service. Provide $STAGING_SERVICE_LOCAL in disconnected environment.\n"
            return 1
        fi
    fi
    if [ -f ~/rust_staging/rust-staging-settings.conf ]; then
        echo "Found existing configuration file, skipping overwrite"
    else
        STAGING_CONFIG_URL="https://raw.githubusercontent.com/phatblinkie/rust_installer/main/configs/rust-staging-settings.conf"
        STAGING_CONFIG_LOCAL="/path/to/local/rust-staging-settings.conf" # Update for disconnected env
        if [ -f "$STAGING_CONFIG_LOCAL" ]; then
            echo "Using local rust-staging-settings.conf: $STAGING_CONFIG_LOCAL"
            cp "$STAGING_CONFIG_LOCAL" ~/rust_staging/rust-staging-settings.conf
        else
            if ! wget -q -O ~/rust_staging/rust-staging-settings.conf "$STAGING_CONFIG_URL"; then
                echo -e "\nERROR: Failed to download rust-staging-settings.conf. Provide $STAGING_CONFIG_LOCAL in disconnected environment.\n"
                return 1
            fi
        fi
    fi

    STAGING_SCRIPT_URL="https://raw.githubusercontent.com/phatblinkie/rust_installer/main/bin/start_rust_staging.sh"
    STAGING_SCRIPT_LOCAL="/path/to/local/start_rust_staging.sh" # Update for disconnected env
    if [ -f "$STAGING_SCRIPT_LOCAL" ]; then
        echo "Using local start_rust_staging.sh: $STAGING_SCRIPT_LOCAL"
        cp "$STAGING_SCRIPT_LOCAL" ~/rust_staging/start_rust_staging.sh
    else
        if ! wget -q -O ~/rust_staging/start_rust_staging.sh "$STAGING_SCRIPT_URL"; then
            echo -e "\nERROR: Failed to download start_rust_staging.sh. Provide $STAGING_SCRIPT_LOCAL in disconnected environment.\n"
            return 1
        fi
    fi
    sed -i "s/USERNAME/$USER/" ~/.config/systemd/user/rust-staging.service
    chmod 0755 ~/rust_staging/start_rust_staging.sh
    # Reload daemon
    systemctl --user daemon-reload
    # Enable linger mode
    loginctl enable-linger

    echo -e "\n You can manage the service with the following commands\n"
    echo -e "systemctl --user start|status|stop rust-staging"
    echo
    echo -e "To see logs in real time, use journalctl -f -u rust-staging"
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
    echo "Oxide update completed"
    cd $OLDPWD
}

show_menu() {
    clear
    echo "===================================================="
    echo " Rust Install Tool - Ver. $script_version"
    echo "===================================================="
    echo " 1. Install pre-requisites"
    echo " 2. Download or Re-Install SteamCMD"
    echo " 3. Install/update Rust"
    echo " 4. Install/update oxide"
    echo " 5. Install/update Rust Staging Branch"
    echo " 6. Install/update oxide on Staging Branch"
    echo " 7. Configure firewall"
    echo " 0. Exit"
    echo "===================================================="
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
