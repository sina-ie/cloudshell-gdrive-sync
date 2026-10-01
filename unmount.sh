#!/usr/bin/env bash
set -Eeuo pipefail

MOUNT_POINT="${HOME}/drive_workspace"
REAL_MOUNT_POINT="/tmp/drive_workspace"

is_mounted() {
    grep -qs "${REAL_MOUNT_POINT}" /proc/mounts 2>/dev/null || \
    grep -qs "${MOUNT_POINT}" /proc/mounts 2>/dev/null || \
    mountpoint -q "${REAL_MOUNT_POINT}" 2>/dev/null || \
    mountpoint -q "${MOUNT_POINT}" 2>/dev/null
}

main() {
    if ! is_mounted; then
        echo "[!] Workspace is not currently mounted."
        exit 0
    fi

    local target="${REAL_MOUNT_POINT}"
    if grep -qs "${MOUNT_POINT}" /proc/mounts 2>/dev/null; then
        target="${MOUNT_POINT}"
    fi
    echo "==> Safely unmounting ${target}..."
    
    if command -v fusermount3 >/dev/null 2>&1; then
        fusermount3 -u "${target}" 2>/dev/null || fusermount3 -u -z "${target}"
    elif command -v fusermount >/dev/null 2>&1; then
        fusermount -u "${target}" 2>/dev/null || fusermount -u -z "${target}"
    else
        sudo umount "${target}" 2>/dev/null || sudo umount -l "${target}"
    fi

    sleep 1

    # Clean up stale symlink if present
    [ -L "${MOUNT_POINT}" ] && rm -f "${MOUNT_POINT}"

    if is_mounted; then
        echo "[✗] Unmount failed. A process may still be accessing the directory."
        exit 1
    else
        echo "[✓] Drive workspace successfully unmounted."
    fi
}

main "$@"