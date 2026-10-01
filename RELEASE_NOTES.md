# Release Notes - v2.1.0: Real-Time FUSE Architecture & Resilience Layer

## 1. What It Was (Legacy Architecture)
In earlier iterations (`v1.x`):
- Relied on batch copying (`sync.sh`, `pull.sh`).
- Updates were not real-time and risked wiping remote files.
- Cloud Shell disk check syntax error: `bash: ((: 14\n22 >= 95: syntax error in expression`.
- Stale FUSE drops threw unrecoverable `Transport endpoint is not connected` errors.

---

## 2. What It Has Become (v2.1.0 Architecture)
- **Real-Time FUSE Virtual Filesystem:** Live reads/writes via `rclone mount --vfs-cache-mode full`.
- **Mount Point Isolation:** Raw mount placed in `/tmp/drive_workspace` with a clean symlink at `~/drive_workspace`.
- **Autonomous Watchdog Daemon:** `health_check.sh --daemon` probes I/O and self-heals broken connections.
- **Robust Endpoint Recovery:** Uses `/proc/mounts` to clean up broken transport endpoints (`ENOTCONN`).
- **Resource Management:** Cache restricted to `--vfs-cache-max-size 2G` for Cloud Shell quota safety.
- **Documentation:** Full English `README.md`, Persian `README.fa.md`, and `CHAT_HISTORY.md`.
