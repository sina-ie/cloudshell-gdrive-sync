#!/usr/bin/env bash
set -uo pipefail

TARGET_TTY="${1:-}"
REMOTE_NAME="gdrive"
REMOTE_FOLDER="Cloudshell_Backup"
LOCAL_PATH="${HOME}/cloudshell-gdrive-sync"
LOG_FILE="${LOCAL_PATH}/rclone_sync.log"
LOCK_FILE="/tmp/rclone_sync.lock"
ERROR_FLAG_FILE="/tmp/.gdrive_sync_error"
SUCCESS_FLAG_FILE="/tmp/.gdrive_sync_success"

# Prevent concurrent executions using an atomic lock directory
if ! mkdir "${LOCK_FILE}" 2>/dev/null; then
    exit 0
fi
trap 'rm -rf "${LOCK_FILE}"' EXIT

# Execute rclone and capture exit status without premature script termination
SYNC_ERR=0
nice -n 19 rclone copy "${REMOTE_NAME}:${REMOTE_FOLDER}" "${LOCAL_PATH}" \
    --update \
    --exclude-from "${LOCAL_PATH}/.gitignore" \
    --log-file="${LOG_FILE}" \
    --log-level NOTICE || SYNC_ERR=$?

CURRENT_TIME=$(date '+%H:%M:%S')

if [ ${SYNC_ERR} -eq 0 ]; then
    rm -f "${ERROR_FLAG_FILE}"
    touch "${SUCCESS_FLAG_FILE}"
    
    # Notify active TTY on success if available
    if [ -n "${TARGET_TTY}" ] && [ -w "${TARGET_TTY}" ]; then
        printf "\n\e[1;32m[✓ GDrive Sync]\e[0m Sync completed successfully at %s.\n" "${CURRENT_TIME}" > "${TARGET_TTY}"
    fi
else
    rm -f "${SUCCESS_FLAG_FILE}"
    
    # Extract the last 5 lines from the log
    LAST_LOGS=$(tail -n 5 "${LOG_FILE}" 2>/dev/null || echo "No log entries found.")

    # Save comprehensive error details for PROMPT_COMMAND consumption
    cat << ERR_MSG > "${ERROR_FLAG_FILE}"
\e[1;31m[✗ GDrive Sync]\e[0m Sync failed (exit code: ${SYNC_ERR}) at ${CURRENT_TIME}.
\e[1;33m--- Last 5 lines from ${LOG_FILE} ---\e[0m
${LAST_LOGS}
\e[1;33m---------------------------------------\e[0m
ERR_MSG

    # Print error notification directly to active TTY if available
    if [ -n "${TARGET_TTY}" ] && [ -w "${TARGET_TTY}" ]; then
        printf "\n%b\n" "$(<"${ERROR_FLAG_FILE}")" > "${TARGET_TTY}"
    fi
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] Sync failed with exit code ${SYNC_ERR}." >> "${LOG_FILE}"
fi

exit ${SYNC_ERR}
