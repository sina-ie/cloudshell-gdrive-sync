#!/usr/bin/env bash
set -Eeuo pipefail

# ==============================================================================
# Cloud Shell & Google Drive Unified FUSE Mount
# پیاده‌سازی فاز ۲ و ۳: اتصال فایل‌سیستم بلادرنگ و کش VFS
# ==============================================================================

REMOTE_NAME="gdrive"
REMOTE_FOLDER="Cloudshell_Backup"
MOUNT_POINT="${HOME}/drive_workspace"
LOG_FILE="${HOME}/cloudshell-gdrive-sync/rclone_mount.log"
CACHE_DIR="${HOME}/.cache/rclone"

check_fuse() {
    if ! command -v fusermount3 >/dev/null 2>&1 && ! command -v fusermount >/dev/null 2>&1; then
        echo "[!] ابزار FUSE یافت نشد. در حال نصب fuse3..."
        sudo apt-get update -qq && sudo apt-get install -y -qq fuse3
    fi
}

is_mounted() {
    mountpoint -q "${MOUNT_POINT}" 2>/dev/null
}

main() {
    echo "==> بررسی وضعیت پیش‌نیازها..."
    check_fuse

    if is_mounted; then
        echo "[✓] نقطه اتصال ${MOUNT_POINT} هم‌اکنون فعال و مانت شده است."
        exit 0
    fi

    mkdir -p "${MOUNT_POINT}"
    mkdir -p "$(dirname "${LOG_FILE}")"
    mkdir -p "${CACHE_DIR}"

    echo "==> در حال اجرای rclone mount به صورت پس‌زمینه (Daemon)..."
    
    # اجرای مانت FUSE با پارامترهای بهینه‌سازی دیسک و ترافیک شبکه
    rclone mount "${REMOTE_NAME}:${REMOTE_FOLDER}" "${MOUNT_POINT}" \
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

    # اعتبارسنجی اتصال موفق
    local attempts=0
    while ! is_mounted; do
        sleep 0.5
        attempts=$((attempts + 1))
        if [ "${attempts}" -ge 20 ]; then
            echo "[✗] خطا در مانت کردن گوگل درایو. لاگ خطا:"
            tail -n 10 "${LOG_FILE}"
            exit 1
        fi
    done

    echo "=========================================================="
    echo "[✓] فضای ذخیره‌سازی ابری با موفقیت متصل شد!"
    echo "مسیر دسترسی در کلود شل: ${MOUNT_POINT}"
    echo "پوشه مقصد در گوگل درایو: ${REMOTE_FOLDER}"
    echo "فایل لاگ: ${LOG_FILE}"
    echo "=========================================================="
}

main "$@"