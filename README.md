# Cloud Shell & Google Drive Unified Storage (FUSE VFS Layer)

A production-grade, real-time, bidirectional filesystem integration between **Google Cloud Shell** and **Google Drive** using `rclone` and `FUSE3` with intelligent VFS disk caching and automated self-healing.

[!Language: Bash](https://www.gnu.org/software/bash/)
[!Engine: rclone](https://rclone.org/)
[!Platform: Google Cloud Shell](https://cloud.google.com/shell)
[!Language: Persian README](README.fa.md)

---

## Architectural Overview

Traditional approaches rely on periodic cron jobs or batch transfer scripts (`rclone sync` / `pull.sh`). These models introduce:
1. **Data Desynchronization:** Edits are not visible until an explicit sync command finishes.
2. **Accidental Deletions:** One-way batch synchronization risks wiping newer changes on either peer.
3. **IDE Friction:** Cloud Shell IDE / VS Code editors cannot smoothly write and save open project files.

### The Solution: Transparent FUSE Layer
This project mounts Google Drive as a local POSIX-compliant virtual filesystem. Using `--vfs-cache-mode full`, file reads and writes happen instantaneously inside a local buffer and are asynchronously synced to Google Drive in the background.

```
+-------------------------------------------------------------+
|                      Google Cloud Shell                     |
|                                                             |
|  User Workspace: ~/drive_workspace                          |
|         |                                                   |
|         v (Symlink Isolation)                               |
|  Mount Point:    /tmp/drive_workspace                       |
|         ^                                                   |
|         |                                                   |
|  Daemon Layer:   rclone mount --vfs-cache-mode full         |
|                  (Cache: ~/.cache/rclone, Limit: 2GB)       |
|         ^                                                   |
|         |                                                   |
|  Watchdog:       health_check.sh --daemon                   |
+---------|---------------------------------------------------+
          | (OAuth2 REST API / Polling 1m)
          v
+-------------------------------------------------------------+
|                        Google Drive                         |
|                   Remote: Cloudshell_Backup                 |
+-------------------------------------------------------------+
```

---

## Key Features

- **Real-Time Bidirectional Sync:** Live file reads/writes with no batch commands required.
- **VFS Disk Optimization:** Read chunks dynamically scale (`32M` to `256M`), keeping persistent storage strictly under `2GB` to respect Cloud Shell's 5GB home limit.
- **Shell Isolation Architecture:** The raw mount resides in `/tmp/drive_workspace` with a clean symlink at `~/drive_workspace`, preventing syntax crashes with Cloud Shell's built-in disk quota monitor (`df` multi-entry parser).
- **Session Automation (`~/.bashrc`):** Mounts automatically upon terminal open and unmounts cleanly upon session disconnect or logout (`HUP/TERM/EXIT` traps).
- **Continuous Health Check & Watchdog:** `health_check.sh` monitors FUSE responsiveness every 60 seconds and triggers automatic self-healing if a deadlock or network drop is detected.

---

## Repository Structure

```text
cloudshell-gdrive-sync/
├── mount.sh              # Core daemon mounting script with VFS configuration
├── unmount.sh            # Graceful and fallback unmount coordinator
├── health_check.sh       # Continuous probe and self-healing watchdog daemon
├── setup_project.sh      # Initial environment bootstrap script
├── README.md             # Full English documentation
├── README.fa.md          # Full Persian documentation
├── CHAT_HISTORY.md       # Complete AI assistant session log & continuation guide
├── legacy_scripts/       # Archived legacy batch sync scripts (pull.sh, sync.sh)
└── .gitignore            # Clean git exclusion rules
```

---

## Quick Start

### 1. Prerequisites
Install `rclone` and `fuse3` in your Google Cloud Shell environment:
```bash
sudo apt-get update -qq && sudo apt-get install -y -qq fuse3 rclone
```

### 3. Mount Google Drive Workspace
```bash
chmod +x ~/cloudshell-gdrive-sync/*.sh
~/cloudshell-gdrive-sync/mount.sh
```

### 4. Enable Automated Persistence
Append the following block to your `~/.bashrc`:
```bash
# ==========================================================
# Google Drive Real-time FUSE Workspace
# ==========================================================
alias cddrive="cd ~/drive_workspace"

# 1. Auto-mount on session start
if [ -x "${HOME}/cloudshell-gdrive-sync/mount.sh" ]; then
    "${HOME}/cloudshell-gdrive-sync/mount.sh" >/dev/null 2>&1 &
fi

# 2. Auto-start watchdog daemon
if [ -x "${HOME}/cloudshell-gdrive-sync/health_check.sh" ]; then
    nohup "${HOME}/cloudshell-gdrive-sync/health_check.sh" --daemon >/dev/null 2>&1 &
fi

# 3. Clean unmount on session exit
_cleanup_gdrive_mount() {
    if [ -x "${HOME}/cloudshell-gdrive-sync/unmount.sh" ]; then
        "${HOME}/cloudshell-gdrive-sync/unmount.sh" >/dev/null 2>&1
    fi
}
trap _cleanup_gdrive_mount HUP TERM EXIT
```

---

## Operations & Management

### Accessing Workspace
```bash
cddrive
```

### Health Check & Diagnostics
Run a one-off probe:
```bash
~/cloudshell-gdrive-sync/health_check.sh
```

Run continuous watchdog in the background:
```bash
nohup ~/cloudshell-gdrive-sync/health_check.sh --daemon >/dev/null 2>&1 &
```

### Inspect Logs
```bash
# Mount daemon log
tail -f ~/cloudshell-gdrive-sync/rclone_mount.log

# Health check watchdog log
tail -f ~/cloudshell-gdrive-sync/health_check.log
```

### Safe Unmount
```bash
~/cloudshell-gdrive-sync/unmount.sh
```

---

## License
This project is licensed under the MIT License.
