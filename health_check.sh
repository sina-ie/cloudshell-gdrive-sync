#!/usr/bin/env bash
set -Eeuo pipefail

# ==============================================================================
# Google Drive FUSE Mount Health Check & Watchdog
# Continuous filesystem probe and automated self-healing
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOUNT_POINT="${HOME}/drive_workspace"
REAL_MOUNT_POINT="/tmp/drive_workspace"
LOG_FILE="${SCRIPT_DIR}/health_check.log"
LOCK_FILE="/tmp/gdrive_health_check.lock"
PID_FILE="/tmp/gdrive_health_check.pid"
PROBE_TIMEOUT=5
CHECK_INTERVAL=60

# Avoid operating inside a broken mount point
cd "${HOME}"

log() {
    local level="$1"
    shift
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [${level}] $*"
    echo "${msg}" >> "${LOG_FILE}"
    if [ -t 1 ]; then
        echo "${msg}"
    fi
}

check_health() {
    # 1. Check if mount point is registered in /proc/mounts or mountpoint
    if ! grep -qs "${REAL_MOUNT_POINT}" /proc/mounts 2>/dev/null && ! mountpoint -q "${REAL_MOUNT_POINT}" 2>/dev/null; then
        log "WARN" "Neither ${REAL_MOUNT_POINT} nor ${MOUNT_POINT} is mounted."
        return 1
    fi

    # 2. Probe I/O responsiveness with timeout to detect FUSE deadlocks
    if ! timeout "${PROBE_TIMEOUT}" ls -f "${MOUNT_POINT}" >/dev/null 2>&1; then
        log "ERROR" "I/O probe failed on ${MOUNT_POINT} after ${PROBE_TIMEOUT}s timeout (FUSE hang)."
        return 1
    fi

    return 0
}

recover_mount() {
    log "WARN" "Initiating mount self-healing and recovery..."

    # Safely unmount (closing fd 200 so children do not inherit the lock)
    if [ -x "${SCRIPT_DIR}/unmount.sh" ]; then
        "${SCRIPT_DIR}/unmount.sh" 200>&- >> "${LOG_FILE}" 2>&1 || true
    else
        fusermount3 -u -z "${REAL_MOUNT_POINT}" 2>/dev/null || true
    fi

    # Clean up any hanging rclone processes targeting this workspace
    pkill -9 -f "rclone mount.*${REAL_MOUNT_POINT}" 2>/dev/null || true
    sleep 1

    # Remount Google Drive workspace
    if [ -x "${SCRIPT_DIR}/mount.sh" ]; then
        "${SCRIPT_DIR}/mount.sh" 200>&- >> "${LOG_FILE}" 2>&1
        if check_health; then
            log "INFO" "[✓] Self-healing succeeded. Mount restored."
            return 0
        fi
    fi

    log "ERROR" "[✗] Self-healing recovery failed."
    return 1
}

run_single_check() {
    if check_health; then
        return 0
    else
        recover_mount
    fi
}

main() {
    if [ "${1:-}" = "--daemon" ]; then
        if [ -f "${PID_FILE}" ]; then
            local existing_pid
            existing_pid=$(cat "${PID_FILE}" 2>/dev/null || true)
            if [ -n "${existing_pid}" ] && kill -0 "${existing_pid}" 2>/dev/null; then
                log "WARN" "Watchdog daemon is already running (PID: ${existing_pid}). Exiting."
                exit 0
            fi
        fi
        echo "$$" > "${PID_FILE}"
        trap 'rm -f "${PID_FILE}"' EXIT HUP INT TERM

        log "INFO" "Mount health watchdog daemon started (Interval: ${CHECK_INTERVAL}s, PID: $$)."
        while true; do
            run_single_check || true
            sleep "${CHECK_INTERVAL}"
        done
    else
        exec 200>"${LOCK_FILE}"
        if ! flock -n 200; then
            exit 0
        fi
        if run_single_check; then
            echo "[✓] Mount point is healthy and responsive."
        else
            exit 1
        fi
    fi
}

main "$@"