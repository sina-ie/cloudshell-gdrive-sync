#!/usr/bin/env bash
set -Eeuo pipefail

# ==============================================================================
# Cloud Shell & Google Drive Unified FUSE Mount
# Real-time FUSE Mount Layer with VFS Caching
# ==============================================================================

REMOTE_NAME="gdrive"
REMOTE_FOLDER="Cloudshell_Backup"
REAL_MOUNT_POINT="/tmp/drive_workspace"
SYMLINK_POINT="${HOME}/drive_workspace"
LOG_FILE="${HOME}/cloudshell-gdrive-sync/rclone_mount.log"
CACHE_DIR="${HOME}/.cache/rclone"

check_fuse() {
    if ! command -v fusermount3 >/dev/null 2>&1 && ! command -v fusermount >/dev/null 2>&1; then
        echo "[!] FUSE utility not found. Installing fuse3 package..."
        sudo apt-get update -qq && sudo apt-get install -y -qq fuse3
    fi
}

is_mounted() {
    grep -qs "${REAL_MOUNT_POINT}" /proc/mounts 2>/dev/null && mountpoint -q "${REAL_MOUNT_POINT}" 2>/dev/null
}

main() {
    echo "==> Checking prerequisites..."
    check_fuse

    if is_mounted; then
        ln -sfn "${REAL_MOUNT_POINT}" "${SYMLINK_POINT}"
        echo "[✓] Mount point ${REAL_MOUNT_POINT} is already active."
        exit 0
    fi

    # Clean up stale/broken transport endpoints before mounting
    if grep -qs "${REAL_MOUNT_POINT}" /proc/mounts 2>/dev/null; then
        fusermount3 -u -z "${REAL_MOUNT_POINT}" 2>/dev/null || sudo umount -l "${REAL_MOUNT_POINT}" 2>/dev/null || true
        sleep 0.5
    fi

    mkdir -p "${REAL_MOUNT_POINT}"
    mkdir -p "$(dirname "${LOG_FILE}")"
    mkdir -p "${CACHE_DIR}"

    echo "==> Starting rclone FUSE mount in background daemon mode..."
    
    # Mount Google Drive with local VFS cache optimization
    rclone mount "${REMOTE_NAME}:${REMOTE_FOLDER}" "${REAL_MOUNT_POINT}" \
        --cache-dir="${CACHE_DIR}" \
        --vfs-cache-mode full \
        --vfs-cache-max-age 24h \
        --vfs-cache-max-size 2G \
        --vfs-read-chunk-size 32M \
        --vfs-read-chunk-size-limit 256M \
        --dir-cache-time 10m \
        --poll-interval 1m \
        --drive-use-trash \
        --daemon \
        --log-file="${LOG_FILE}" \
        --log-level NOTICE

    # Validate mount state
    local attempts=0
    while ! is_mounted; do
        sleep 0.5
        attempts=$((attempts + 1))
        if [ "${attempts}" -ge 20 ]; then
            echo "[✗] Failed to mount Google Drive. Recent error logs:"
            tail -n 10 "${LOG_FILE}"
            exit 1
        fi
    done

    ln -sfn "${REAL_MOUNT_POINT}" "${SYMLINK_POINT}"

    echo "=========================================================="
    echo "[✓] Cloud storage workspace mounted successfully!"
    echo "Workspace:     ${SYMLINK_POINT} -> ${REAL_MOUNT_POINT}"
    echo "Remote Target: ${REMOTE_NAME}:${REMOTE_FOLDER}"
    echo "Log File:      ${LOG_FILE}"
    echo "=========================================================="
}

main "$@"