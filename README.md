# Rust Installer

A simple tool to set up and manage a Rust server on Linux, supporting **Ubuntu** and **RHEL 9** (or CentOS-compatible distributions).

## Overview

The `rust_installer` script automates the installation and configuration of a Rust game server, including the main branch and staging branch, with optional Oxide mod support. It is designed to run as a non-root user, prompting for sudo credentials only when needed (e.g., for installing prerequisites or configuring the firewall). The script supports both online and disconnected environments by allowing local file paths for downloads.

### Features
- Installs required libraries (`lib32gcc-s1` for Ubuntu, `glibc.i686` and `libgcc.i686` for RHEL 9) using `apt` or `dnf`.
- Downloads and installs SteamCMD.
- Installs or updates the Rust server (main or staging branch).
- Installs or updates Oxide for either branch.
- Creates user-level systemd services (`rust-main.service`, `rust-staging.service`) for easy server management.
- Generates configuration files (`rust-main-settings.conf`, `rust-staging-settings.conf`) in `~/rust_main/` or `~/rust_staging/`.
- Configures the firewall (`ufw` for Ubuntu, `firewalld` for RHEL 9) using ports defined in configuration files.
- Supports disconnected environments with local file paths for downloads.

## Installation

1. **Run the Script**:
   - As a non-root user, execute the following command to download and run the installer:
     ```bash
     wget -q -O - https://raw.githubusercontent.com/phatblinkie/rust_installer/main/install_or_update_rust.sh | bash
     ```
   - The script will prompt for your sudo password when elevated privileges are required (options 1 and 7).

2. **Disconnected Environment Setup**:
   - For systems without internet access, pre-download the following files on a connected system and transfer them to your server (e.g., to `/home/$USER/downloads/`):
     ```bash
     wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz -O /path/to/local/steamcmd_linux.tar.gz
     wget https://github.com/OxideMod/Oxide.Rust/releases/latest/download/Oxide.Rust-linux.zip -O /path/to/local/Oxide.Rust-linux.zip
     wget https://downloads.oxidemod.com/artifacts/Oxide.Rust/staging/Oxide.Rust-linux.zip -O /path/to/local/Oxide.Rust-linux-staging.zip
     wget https://raw.githubusercontent.com/phatblinkie/rust_installer/main/servicefiles/rust-main.service -O /path/to/local/rust-main.service
     wget https://raw.githubusercontent.com/phatblinkie/rust_installer/main/servicefiles/rust-staging.service -O /path/to/local/rust-staging.service
     wget https://raw.githubusercontent.com/phatblinkie/rust_installer/main/configs/rust-main-settings.conf -O /path/to/local/rust-main-settings.conf
     wget https://raw.githubusercontent.com/phatblinkie/rust_installer/main/configs/rust-staging-settings.conf -O /path/to/local/rust-staging-settings.conf
     wget https://raw.githubusercontent.com/phatblinkie/rust_installer/main/bin/start_rust_main.sh -O /path/to/local/start_rust_main.sh
     wget https://raw.githubusercontent.com/phatblinkie/rust_installer/main/bin/start_rust_staging.sh -O /path/to/local/start_rust_staging.sh
     ```
   - Update the `*_LOCAL` variables in the script with the paths to these files.

3. **Local Package Repository** (RHEL 9):
   - For disconnected RHEL 9 systems, set up a local `dnf` repository:
     ```bash
     sudo mkdir -p /path/to/local/repo
     # Copy RPMs for glibc.i686, rsync, unzip, wget, libgcc.i686
     sudo createrepo /path/to/local/repo
     sudo nano /etc/yum.repos.d/local.repo
     ```
     Add to `/etc/yum.repos.d/local.repo`:
     ```ini
     [local-repo]
     name=Local Repository
     baseurl=file:///path/to/local/repo
     enabled=1
     gpgcheck=0
     ```
     Install dependencies:
     ```bash
     sudo dnf install -y glibc.i686 rsync unzip wget libgcc.i686
     ```

## Usage

The script provides an interactive menu with the following options:

1. **Install pre-requisites**: Installs required libraries (`lib32gcc-s1` for Ubuntu, `glibc.i686` and `libgcc.i686` for RHEL 9). Requires sudo.
2. **Download or Re-Install SteamCMD**: Installs or updates SteamCMD.
3. **Install/update Rust**: Installs or updates the Rust server (main branch) and sets up `rust-main.service` and `rust-main-settings.conf`.
4. **Install/update Oxide**: Updates Oxide for the main branch.
5. **Install/update Rust Staging Branch**: Installs or updates the Rust server (staging branch) and sets up `rust-staging.service` and `rust-staging-settings.conf`.
6. **Install/update Oxide on Staging Branch**: Updates Oxide for the staging branch.
7. **Configure firewall**: Opens ports defined in `rust-main-settings.conf` and `rust-staging-settings.conf` using `ufw` (Ubuntu) or `firewalld` (RHEL 9). Requires sudo.
0. **Exit**: Exits the script.

Run the script:
```bash
bash install_or_update_rust.sh
