# Cloud Shell & Google Drive Sync - Architecture Evolution & Internal Log

**Repository:** `sina-ie/cloudshell-gdrive-sync`
**Target Release:** `v2.1.1`  
**Architecture State:** Production-Ready Real-Time FUSE Mount Layer  

---

## 1. Project Background & Evolution

### Release v1.0.0: Initial Batch Synchronization
- Direct batch sync mechanisms using `rclone copy` and `rclone sync`.
- Synchronization was batch-driven and non-real-time, leading to synchronization latency.
- Lacked atomic concurrency locks and comprehensive error diagnostics.

### Release v1.0.1: Concurrency Control & TTY Telemetry
- Implemented atomic mutex locking via `mkdir /tmp/rclone_sync.lock` with cleanup traps.
- Added interactive terminal telemetry targeting `$TARGET_TTY` with exit code capturing (`SYNC_ERR`).
- Introduced state signal files (`/tmp/.gdrive_sync_error`, `/tmp/.gdrive_sync_success`) for `PROMPT_COMMAND` status banners.
- Scheduled operations with `nice -n 19` to preserve Cloud Shell compute responsiveness.

### Release v2.0.0: Initial Virtual Filesystem (FUSE) Architecture
- Migrated storage backend from batch synchronization to real-time `rclone mount`.
- Encountered `/google/devshell/bashrc.google` multi-line quota calculation crashes.
- Encountered transport endpoint disconnections (`ENOTCONN`) upon network timeout.

### Current Architecture (v2.1.0)
- POSIX-compliant virtual filesystem powered by `rclone mount` with FUSE3 and VFS disk caching (`--vfs-cache-mode full`).
- Raw mount isolated at `/tmp/drive_workspace` with a clean symlink at `~/drive_workspace` to bypass Cloud Shell's internal `df` calculation error.
- Dedicated watchdog daemon (`health_check.sh --daemon`) probing I/O responsiveness every 60s with automatic remounting and process cleanup.
- Local VFS cache capped at `2GB` (`--vfs-cache-max-size 2G`) to protect the 5GB home quota.
- Standardized English documentation and dual automated/manual setup paths.

---

## 2. Chronological Log of Issues & Resolutions

### Issue 1: `Exit 126` (Permission Denied)
- **Cause:** Shell scripts lacked execution permissions.
- **Fix:** Ran `chmod +x ~/cloudshell-gdrive-sync/*.sh`.

### Issue 2: OAuth2 Token Expiration & Headless Authentication
- **Cause:** Google retired OOB (Out-Of-Band) verification; web browser could not be launched inside headless Cloud Shell.
- **Fix:** Generated token via local `rclone authorize` and safely injected into `~/.config/rclone/rclone.conf`.

### Issue 3: Cloud Shell Disk Quota Prompt Syntax Error
- **Console Error:** `bash: ((: 14\n22 >= 95: syntax error in expression (error token is "22 >= 95")`
- **Cause:** `/google/devshell/bashrc.google` evaluated `df` inside `$HOME`. Multi-line output broke the arithmetic expression.
- **Fix:** Mounted FUSE to `/tmp/drive_workspace` and created a symlink at `~/drive_workspace`.

### Issue 4: Watchdog Subshell Duplication & File Lock Leak
- **Cause:** Subshell evaluation `$(pgrep ...)` inherited process parameters and child daemons inherited fd 200.
- **Fix:** Replaced with PID file verification (`/tmp/gdrive_health_check.pid`) and closed file descriptor 200 (`200>&-`).

### Issue 5: `Transport endpoint is not connected` on Dead Mounts
- **Cause:** When rclone terminated, `stat()` failed with ENOTCONN, causing `mountpoint -q` to return 1. Scripts thought the directory was unmounted and skipped `fusermount3 -u -z`.
- **Fix:** Used `/proc/mounts` as the primary truth source for kernel mount detection.

---

## 3. Resume & Handover Guide for Future Sessions

To continue development in future sessions:
1. Check mount status: `grep -qs /tmp/drive_workspace /proc/mounts && ls -la ~/drive_workspace`
2. Check watchdog daemon: `pgrep -fa "health_check.sh"`
3. Note: All private drafts, experimental logs, and development scratchpads are quarantined inside the `private/` folder (git-ignored).
