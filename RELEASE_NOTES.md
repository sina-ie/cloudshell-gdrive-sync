# Changelog & Release Notes

All notable changes to this project are documented below in accordance with [Keep a Changelog](https://keepachangelog.com/) and [Semantic Versioning](https://semver.org/).

## Release v1.0.0: Initial Batch Synchronization Architecture

### Added
- **Initial rclone Batch Engine:** Core script suite (`pull.sh`, `sync.sh`) using `rclone copy` and `rclone sync` to transfer data between Google Cloud Shell and Google Drive (`Cloudshell_Backup`).
- **Exclusion Filtering:** Added support for `.gitignore` file masking to prevent synchronizing temporary, cache, and build files.
- **Environment Setup:** Basic project initialization helper for repository directories.

### Operational Evaluation & Readiness
- **Operational Status:** Functional for manual, single-user batch transfers.
- **Verified Workflows:** Basic ad-hoc file pulls and pushes run cleanly when executed sequentially.

### Deficiencies & Known Bugs
- **No Concurrency Controls:** Concurrent script invocations triggered overlapping rclone processes, risking index and file corruption.
- **Sync Latency:** Updates required manual command triggers or terminal exit hooks, resulting in data desynchronization during development.
- **Destructive Sync Hazards:** One-way `rclone sync` mirroring posed a high risk of wiping valid remote files if local files were deleted or uncommitted.
- **No Network Resilience:** Network interruptions abruptly terminated processes without reporting meaningful diagnostics to active terminals.

---

## Release v1.0.1: Concurrency Protection & Telemetry Enhancement

### Added
- **Atomic Directory Lock:** Introduced mutex locking using atomic `mkdir /tmp/rclone_sync.lock` paired with shell `EXIT` traps to eliminate concurrent execution conflicts.
- **Target TTY Notification:** Added direct active terminal device detection (`TARGET_TTY`) to stream colored status alerts (`[✓ GDrive Sync]` / `[✗ GDrive Sync]`) directly to interactive sessions.
- **Status Flag Signaling:** Introduced `/tmp/.gdrive_sync_success` and `/tmp/.gdrive_sync_error` flags for dynamic integration into shell prompt hooks (`PROMPT_COMMAND`).
- **Diagnostic Log Trapping:** Automated extraction of trailing log output (`tail -n 5`) upon failures, reporting explicit exit codes to active sessions.
- **Process Niceness:** Applied `nice -n 19` to background synchronization tasks to prioritize interactive shell workloads.

### Changed
- Replaced non-zero exit crashes with captured exit codes (`SYNC_ERR`) to ensure comprehensive logging before terminal notification.

---

## Release v2.1.0: Real-Time FUSE Architecture & Resilience Layer

### Architectural Shift
Replaced legacy batch scripts (`v1.x`) with a real-time POSIX-compliant virtual filesystem.

### Legacy Pain Points Resolved
- Batch delays replaced by immediate bidirectional reads/writes.
- Disk quota evaluation syntax crashes (`bash: ((: ... >= 95)`) eliminated via symlink isolation.
- Dangling transport endpoints (`ENOTCONN`) automatically recovered via watchdog polling.

- **Real-Time FUSE Virtual Filesystem:** Live reads/writes via `rclone mount --vfs-cache-mode full`.
- **Mount Point Isolation:** Raw mount placed in `/tmp/drive_workspace` with a clean symlink at `~/drive_workspace`.
- **Autonomous Watchdog Daemon:** `health_check.sh --daemon` probes filesystem I/O and self-heals broken connections.
- **Robust Endpoint Recovery:** Uses `/proc/mounts` to clean up broken transport endpoints (`ENOTCONN`).
- **Resource Management:** Cache restricted to `--vfs-cache-max-size 2G` for Cloud Shell quota safety.
- **Documentation:** Full English `README.md`, Persian `README.fa.md`, and `CHAT_HISTORY.md`.
