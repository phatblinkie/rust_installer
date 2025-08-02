# Rust Installer

A simple tool to set up and manage a Rust server on Linux, supporting **Ubuntu** and **RHEL 9** (or CentOS-compatible distributions).

## Overview

The `rust_installer` script automates the installation and configuration of a Rust game server, including the main branch and staging branch, with optional Oxide mod support. It is designed to run as a non-root user, prompting for sudo credentials only when needed (e.g., for installing prerequisites or configuring the firewall). The script supports both online and disconnected environments by allowing local file paths for downloads.

### Features
- Installs required libraries (`lib32gcc-s1` for Ubuntu, `glibc.i686` and `libgcc.i686` for RHEL 9) using `apt` or `dnf`.
- Compatible with rpm and deb based distros
- Downloads and installs SteamCMD.
- Installs or updates the Rust server (main or staging branch).
- Installs or updates Oxide for either branch.
- Creates user-level systemd services (`rust-main.service`, `rust-staging.service`) for easy server management.
- Generates configuration files (`rust-main-settings.conf`, `rust-staging-settings.conf`) in `~/rust_main/` or `~/rust_staging/`.
- Configures the firewall (`ufw` for Ubuntu, `firewalld` for RHEL 9) using ports defined in configuration files above. (edit them first)
- Supports disconnected environments with local file paths for downloads.  you can git clone, or run as a single command "wget -q -O - https://raw.githubusercontent.com/phatblinkie/rust_installer/main/install_or_update_rust.sh | bash"

## Installation

1. **Run the Script directly**:
   - As a non-root user, execute the following command to download and run the installer:
     ```bash
     wget -q -O - https://raw.githubusercontent.com/phatblinkie/rust_installer/main/install_or_update_rust.sh | bash
     ```
   - The script will prompt for your sudo password when elevated privileges are required (options 1 and 7).

2. **clone the repository**:
   - As a non-root user, execute the following command:
     ```bash
     cd ~
     git clone https://github.com/phatblinkie/rust_installer
     cd rust_installer
     ./install_or_update_rust.sh
     ```
     
3. **Disconnected Environment Setup**:
   - For systems without internet access, upload this repository to /home/username/rust_installer
     ```bash
     cd ~
     cd rust_installer
     ./install_or_update_rust.sh
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
8. **Start main rust server**: starts the main branch rust server
9. **Stop main rust server**: stops the main branch rust server
0. **Exit**: Exits the script.

