Rust Server Menu (Windows) v1.5.1

A single-file Windows menu script for installing, running, and maintaining a Rust dedicated server. It uses only built-in Windows tools (cmd, curl, robocopy, forfiles) and supports configuration via an interactive menu or a config.env file.

This script is designed to be simple, repeatable, and safe. It avoids fragile quoting, performs safe backups, and keeps your configuration separate from the script.
Highlights

    One menu to install/update Rust (SteamCMD), Oxide (uMod), and popular extensions (RustEdit, Discord, Chaos).
    Start server in a restart-on-exit loop with clear logging and a 10 second countdown.
    Safe users.cfg management: cmd-only upsert of ownerid/moderatorid on each launch.
    Built-in backups on server exit with retention pruning.
    Interactive Configure flow (blank = keep) with clear sections; settings persist to config.env.
    Minimal dependencies: Windows 10 or newer; uses curl, robocopy, forfiles, and PowerShell only for zip extraction and a download fallback.

Menu actions

    Install/Reinstall SteamCMD.
    Install/Update Rust dedicated server (AppID 258550).
    Install/Update Oxide (uMod).
    Install latest extension DLLs:
        RustEdit
        Discord
        Chaoscode
    Start server with:
        Restart-on-exit loop.
        users.cfg upsert (owner/mod) before each launch.
        Optional custom map URL.
        +logfile enabled.
    Stop server gracefully and block auto-restart.
    Create timestamped backups on exit and prune old backups by retention policy.
    Configure all common settings interactively and persist them to ROOT_DIR\config.env.

Requirements

    Windows 10 or later.
    Internet access for downloads.
    Enough disk space for the server and backups.
    Run from an account with permission to create folders under the chosen ROOT_DIR (default C:\rustserver).

Quick start

    Save the script as a .bat file, for example RustServerMenu.bat.

    Double-click the .bat, or run from Command Prompt:
    
```bat
C:\> path\to\RustServerMenu.bat
```
    Use the menu:

    1: Install/Reinstall SteamCMD
    2: Install/Update Rust
    3–6: Install/Update extensions (optional)
    9: Start Rust server (writes users.cfg, logs, restart loop)
    C: Configure settings (edit and save)

The script automatically copies itself to ROOT_DIR (default C:\rustserver) for convenience.
Configuration

You can configure settings in two ways:

    Interactive: Choose C) Configure settings. Prompts are organized in clear sections. Press Enter to keep the current value; nothing gets erased when you leave a field blank.

    File-based: Edit ROOT_DIR\config.env manually. This file is loaded on startup and overrides the defaults embedded in the script.

config.env keys

    USE_CUSTOM_MAP_URL, SERVER_LEVELURL
    SERVER_HOSTNAME, SERVER_DESCRIPTION, SERVER_URL, SERVER_HEADERIMAGE, SERVER_TAGS
    PUBLIC_IP, PRIVATE_IP
    OWNER_STEAM_ID, MODERATOR_STEAM_ID
    GAMEPORT, RUSTPLUSPORT, QUERYPORT, RCONPORT
    SERVER_SEED, SERVER_WORLDSIZE, MAX_PLAYERS
    RCONPASSWORD, SERVER_SAVE_INTERVAL
    IDENTITY_NAME, GAME_LOGFILE
    BACKUP_RETENTION_DAYS

Example config.env
```ini
# Rust Server Menu config.env
# One KEY=VALUE per line. Blank values are allowed.

USE_CUSTOM_MAP_URL=true
SERVER_LEVELURL=http://your.map/url.map

SERVER_HOSTNAME=Your Rust Server
SERVER_DESCRIPTION=Welcome to my server
SERVER_URL=https://example.com
SERVER_HEADERIMAGE=https://example.com/header.png
SERVER_TAGS=biweekly,NA,pve

PUBLIC_IP=203.0.113.10
PRIVATE_IP=192.168.1.10

OWNER_STEAM_ID=76561198000000000
MODERATOR_STEAM_ID=

GAMEPORT=28015
RUSTPLUSPORT=28017
QUERYPORT=28016
RCONPORT=28016

SERVER_SEED=12345
SERVER_WORLDSIZE=4500
MAX_PLAYERS=10
RCONPASSWORD=changeme
SERVER_SAVE_INTERVAL=180

IDENTITY_NAME=mapfiles
GAME_LOGFILE=logfile.txt

BACKUP_RETENTION_DAYS=7
```

Notes:

    Special characters: Avoid % and ! when using the in-script Configure flow. If you need them, edit config.env directly.
    Identity controls where users.cfg resides: ServerPath\server\IDENTITY_NAME\cfg\users.cfg.

Users and permissions (users.cfg)

Each time you start the server (option 9), the script:

    Ensures the cfg folder exists for your identity.
    Removes any existing ownerid/moderatorid lines.
    Appends ownerid and moderatorid from your configuration if set.

This is done with pure cmd (no PowerShell) to avoid quoting issues.
Backups and retention

On every server exit (option 9 loop), the script:

    Creates a timestamped snapshot of:
        ServerPath\oxide (if exists)
        ServerPath\server (if exists)
    Skips backups while RustDedicated.exe is running (to avoid corruption).
    Prunes backups older than BACKUP_RETENTION_DAYS.

Backups live under ROOT_DIR\backups\YYYYMMDD-HHMMSS.
Start/stop behavior

    Start (option 9):
        10 second countdown (Ctrl+C to abort).
        Writes users.cfg entries.
        Launches RustDedicated.exe with +logfile and your configured arguments.
        Optional +server.levelurl if USE_CUSTOM_MAP_URL=true.

    Stop (option 8):
        Creates a stop.flag so the loop won’t relaunch.
        Requests the Rust process to exit and waits up to 60 seconds.

Networking and ports

The script exposes these arguments:

    +server.port (GAMEPORT)
    +queryport (QUERYPORT)
    +rcon.port (RCONPORT)
    +app.port (RUSTPLUSPORT)
    +app.publicip  (https://whatismyip.com used so facepunch knows what address to send people to)
    +app.listenip  (the private ip on your computer, if its public, use that and not a private address, but dont leave blank)

Open or forward these ports as needed on your firewall and router.
Extensions - Installers are included for:

    Oxide (uMod) from uMod.org
    RustEdit extension DLL
    Discord extension DLL
    Chaoscode extension DLL

The script downloads each payload and places the DLL into:

    ServerPath\RustDedicated_Data\Managed

Logging

    Rust server writes to +logfile "GAME_LOGFILE" under ServerPath.
    The menu itself prints clear progress messages and errors.

Safety and notes

    RCON password is stored in plain text in config.env and passed on the command line; protect access to this system.
    The script copies itself to ROOT_DIR for convenience. You can run either copy.
    The menu uses standard Windows tools. PowerShell is used only for unzip and a download fallback.

License

MIT License. See LICENSE for details.
Credits

    Facepunch Studios for Rust.
    uMod and extension authors for their work.
    Myself - phatblinkie  :)

Support

Open an issue with:

    Windows version
    Script version (1.5.1)
    What you ran and the exact output
    Your config.env (omit sensitive values)
