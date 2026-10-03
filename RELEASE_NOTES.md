# Changelog & Release Notes

All notable changes to this project are documented below in accordance with [Keep a Changelog](https://keepachangelog.com/) and [Semantic Versioning](https://semver.org/).

## Release v1.0.0: Initial Batch Synchronization Architecture

### Added
- **Initial rclone Batch Engine:** Core script suite (`pull.sh`, `sync.sh`) using `rclone copy` and `rclone sync` to transfer data between Google Cloud Shell and Google Drive (`Cloudshell_Backup`).
- **Exclusion Filtering:** Added support for `.gitignore` file masking to prevent synchronizing temporary, cache, and build files.
- **Environment Setup:** Basic project initialization helper for repository directories.

### Operational Evaluation & Readiness
- **Operational Status:** Legacy / Deprecated. Functional only for ad-hoc, manual single-user batch transfers.
- **Verified Workflows:** Direct execution of `pull.sh` and `sync.sh`.

### Deficiencies & Known Bugs
- **No Concurrency Guard:** Simultaneous script triggers caused race conditions and corrupted transfer states.
- **Sync Latency:** File updates remained invisible to editors until manual batch triggers finished.
- **Mirroring Hazards:** One-way `rclone sync` risked permanently deleting remote data if local files were deleted.
- **Zero Network Fault Tolerance:** Network hiccups terminated operations immediately without diagnostics.

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

### Operational Evaluation & Readiness
- **Operational Status:** Partially operational; intended for non-concurrent batch jobs.

### Deficiencies & Known Bugs
- **Sync Latency:** File edits are delayed until an explicit sync command runs; not visible to Cloud Shell Editor in real-time.
- **Cloud Shell Quota Crash:** Running batch checks inside `$HOME` triggers multi-line parser errors in `/google/devshell/bashrc.google` (`bash: ((: ... >= 95)`).
- **Token Stalling:** Expired OAuth tokens cause background tasks to fail silently without automatic recovery.

---

## Release v2.0.0: Initial Virtual Filesystem (FUSE) Architecture

### Added
- **FUSE3 POSIX Filesystem Integration:** Replaced batch copy/sync pipelines with `rclone mount`.
- **Transparent File I/O:** Standard POSIX read/write calls routed directly to cloud storage.
- **Basic VFS Cache:** Introduced `--vfs-cache-mode writes` for responsive file writes.

### Operational Evaluation & Readiness
- **Operational Status:** Partially operational; proof-of-concept verified real-time editor writes.

### Deficiencies & Known Bugs
- **Cloud Shell Quota Parser Failure:** Mounting directly under `${HOME}/drive_workspace` caused `/google/devshell/bashrc.google` to crash:
  `bash: ((: 14\n22 >= 95: syntax error in expression (error token is "22 >= 95")`
- **Dead Transport Endpoints:** Network dropouts caused orphaned FUSE mountpoints (`ENOTCONN`), freezing file browsers and requiring manual root intervention.
- **Unbounded Cache Growth:** VFS cache lacked hard limits, leading to potential exhaustion of Cloud Shell's 5GB storage quota.

---

## Release v2.1.0: Real-Time FUSE Architecture & Resilience Layer

### Added
- **Isolated Mount Architecture:** Moved physical mount point to `/tmp/drive_workspace` and established a symlink at `~/drive_workspace`, completely bypassing the Cloud Shell `df` multi-entry arithmetic parsing bug.
- **Autonomous Self-Healing Watchdog:** Added `health_check.sh` daemon with automated 60-second polling, PID lockfile concurrency enforcement, and unmount fallback logic (`fusermount3 -u -z`).
- **Kernel Mount State Verification:** Replaced unreliable `mountpoint -q` checks with authoritative `/proc/mounts` queries to detect dead endpoints (`ENOTCONN`).
- **Strict VFS Cache Boundaries:** Configured `--vfs-cache-mode full` and `--vfs-cache-max-size 2G` with dynamically expanding read chunks (`32M` to `256M`).
- **Clean Shell Traps:** Added robust session exit traps (`HUP`, `TERM`, `EXIT`) in `~/.bashrc` to flush writes and prevent orphaned background daemons.

### Operational Evaluation & Readiness
- **Operational Status:** Production-ready and verified across Google Cloud Shell environments.
- **Verified Workflows:** Seamless file creation, bidirectional synchronization, zero editor lag, automatic recovery from connection loss, and zero syntax collisions with system quota monitors.

### Deficiencies & Known Bugs
- None identified in supported environments.

---

## Release v2.1.1: Production Polish & Unified Architecture Specification

### Added
- **Unified Quick Start Matrix:** Restored missing step 2 (`rclone config`) in `README.md` and added clear Dual Option setup instructions (One-Click Installer vs. Manual Setup).
- **All-English Architecture Reference:** Fully converted `README.fa.md` into a formal operational engineering specification in English.
- **Subshell & Descriptor Audit:** Confirmed all scripts close internal mutex file descriptors (`200>&-`, `201>&-`) across subshells and background processes.

### Operational Evaluation & Readiness
- **Operational Status:** Production-Ready (Verified on Google Cloud Shell).
- **Integrity:** Zero orphaned mounts, clean process exit, and full POSIX compatibility inside Cloud Shell Editor (VS Code).

### Environmental Constraints & Known Limitations
- **Ephemeral Container `/tmp` Storage:** In Cloud Shell, `/tmp` is wiped upon VM rebuild or prolonged inactivity. The automated session hook in `~/.bashrc` transparently restores the mount on login.
- **Headless Browser Requirement:** Headless OAuth token exchanges require generating the token on a workstation with `rclone authorize "drive"`.
