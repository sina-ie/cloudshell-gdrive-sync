#!/usr/bin/env bash
set -Eeuo pipefail

MOUNT_POINT="${HOME}/drive_workspace"

is_mounted() {
    mountpoint -q "${MOUNT_POINT}" 2>/dev/null
}

main() {
    if ! is_mounted; then
        echo "[!] مسیر ${MOUNT_POINT} در حال حاضر مانت نیست."
        exit 0
    fi

    echo "==> در حال قطع اتصال امن (Unmount) از ${MOUNT_POINT}..."
    
    if command -v fusermount3 >/dev/null 2>&1; then
        fusermount3 -u "${MOUNT_POINT}" 2>/dev/null || fusermount3 -u -z "${MOUNT_POINT}"
    elif command -v fusermount >/dev/null 2>&1; then
        fusermount -u "${MOUNT_POINT}" 2>/dev/null || fusermount -u -z "${MOUNT_POINT}"
    else
        sudo umount "${MOUNT_POINT}" 2>/dev/null || sudo umount -l "${MOUNT_POINT}"
    fi

    sleep 1

    if is_mounted; then
        echo "[✗] قطع اتصال ناموفق بود. ممکن است پروسه‌ای در حال استفاده از دایرکتوری باشد."
        exit 1
    else
        echo "[✓] اتصال درایو با موفقیت قطع شد."
    fi
}

main "$@"