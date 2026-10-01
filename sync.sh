#!/usr/bin/env bash
set -euo pipefail

REMOTE_NAME="gdrive"
REMOTE_FOLDER="Cloudshell_Backup"
LOCAL_PATH="${HOME}/cloudshell-gdrive-sync"
LOG_FILE="${LOCAL_PATH}/rclone_sync.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting sync to ${REMOTE_NAME}:${REMOTE_FOLDER}..." | tee -a "${LOG_FILE}"

rclone sync "${LOCAL_PATH}" "${REMOTE_NAME}:${REMOTE_FOLDER}" \
    --exclude-from "${LOCAL_PATH}/.gitignore" \
    --log-file="${LOG_FILE}" \
    --log-level NOTICE \
    --stats 10s \
    -P

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sync completed successfully." | tee -a "${LOG_FILE}"
