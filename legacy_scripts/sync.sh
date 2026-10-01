#!/usr/bin/env bash
set -euo pipefail

REMOTE_NAME="gdrive"
REMOTE_FOLDER="Cloudshell_Backup"
LOCAL_PATH="${HOME}/cloudshell-gdrive-sync"
LOG_FILE="${LOCAL_PATH}/rclone_sync.log"

# Check if stdout is attached to a terminal
PROGRESS_FLAG=""
if [ -t 1 ]; then
    PROGRESS_FLAG="-P"
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting auto-sync..." >> "${LOG_FILE}"

rclone sync "${LOCAL_PATH}" "${REMOTE_NAME}:${REMOTE_FOLDER}" \
    --exclude-from "${LOCAL_PATH}/.gitignore" \
    --log-file="${LOG_FILE}" \
    --log-level NOTICE \
    --stats 10s \
    ${PROGRESS_FLAG}

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Auto-sync finished." >> "${LOG_FILE}"
