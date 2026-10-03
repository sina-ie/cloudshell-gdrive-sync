# Cloud Shell & Google Drive Engineering & Operations Specification (FUSE VFS)

An in-depth technical specification and operational reference manual for the real-time, bidirectional filesystem integration connecting **Google Drive** to **Google Cloud Shell** using `rclone`, `FUSE3`, and full local VFS caching with autonomous self-healing capabilities.

---

## Why This Architecture?

Traditional batch synchronization scripts (`pull.sh` and `sync.sh`) suffer from critical operational limitations:
1. **Lack of Real-Time Consistency:** Changes are not propagated until a batch command is manually or periodically executed.
2. **Risk of Accidental Data Overwrites:** Unidirectional mirrors can overwrite or delete recent remote modifications.
3. **Editor Incompatibility:** Cloud Shell Editor cannot seamlessly read and write directly to the workspace without sync conflicts.

### The FUSE Solution:
Google Drive is mounted as a local POSIX filesystem at `~/drive_workspace`. Writes are recorded instantaneously in a local cache buffer and uploaded asynchronously without blocking terminal sessions.

---

## Core Features & Design Principles

* **Real-Time Bidirectional Sync:** File changes reflect instantly between Cloud Shell and Google Drive.
* **Mount Isolation Strategy:** Mounting to `/tmp/drive_workspace` and exposing via a symlink at `~/drive_workspace` prevents syntax errors in Cloud Shell's internal disk quota checker (`bash: ((: ... >= 95)`).
* **Disk Quota Protection:** Local cache is strictly capped at 2GB (`--vfs-cache-max-size 2G`) to protect Cloud Shell's 5GB home directory limit.
* **Lifecycle Automation:** Automatic mount restoration upon shell startup and safe unmounting via `trap` upon shell exit.
* **Autonomous Watchdog Daemon:** `health_check.sh` verifies filesystem responsiveness every 60 seconds and automatically recovers broken endpoints without manual intervention.

---

## Directory Layout

```text
cloudshell-gdrive-sync/
├── mount.sh              # Primary daemon bootstrap mounting script
├── unmount.sh            # Safe teardown and cache-flushing script
├── health_check.sh       # Periodic health monitor and self-healing watchdog
├── setup_project.sh      # Private workspace generator for GitHub
├── README.md             # Main repository guide
├── README.fa.md          # Supplementary engineering specifications
├── legacy_scripts/       # Archived v1 batch scripts (pull.sh, sync.sh)
└── .gitignore            # Repository artifact ignore rules
```

---

## Quick Deployment Guide

### 1. Automated Installation
```bash
cd ~/cloudshell-gdrive-sync && ./install.sh
```

### 2. Manual Step-by-Step Installation
```bash
sudo apt-get update -qq && sudo apt-get install -y -qq fuse3 rclone
```

### ۲. احراز هویت اولیه گوگل درایو
```bash
rclone config
```
*نکته: در صورتی که در ترمینال بدون مرورگر هستید، دستور `rclone authorize` را روی کامپیوتر شخصی خود اجرا کرده و توکن تولیدشده را وارد کنید.*

### ۳. فعال‌سازی مجوزهای اجرایی و مانت
```bash
chmod +x ~/cloudshell-gdrive-sync/*.sh
~/cloudshell-gdrive-sync/mount.sh
```

### ۴. پایدارسازی در `~/.bashrc`
قطعه کد زیر را در انتهای فایل `~/.bashrc` قرار دهید:

```bash
# ==========================================================
# Google Drive Real-time FUSE Workspace
# ==========================================================
alias cddrive="cd ~/drive_workspace"

# 1. Automatically mount on shell startup
if [ -x "${HOME}/cloudshell-gdrive-sync/mount.sh" ]; then
    "${HOME}/cloudshell-gdrive-sync/mount.sh" >/dev/null 2>&1 &
fi

# 2. Launch health check watchdog daemon
if [ -x "${HOME}/cloudshell-gdrive-sync/health_check.sh" ]; then
    nohup "${HOME}/cloudshell-gdrive-sync/health_check.sh" --daemon >/dev/null 2>&1 &
fi

# 3. Safely unmount upon session exit
_cleanup_gdrive_mount() {
    local shell_count
    shell_count=$(pgrep -u "${USER}" -x bash 2>/dev/null | wc -l)
    if [ "${shell_count}" -le 1 ] && [ -x "${HOME}/cloudshell-gdrive-sync/unmount.sh" ]; then
        "${HOME}/cloudshell-gdrive-sync/unmount.sh" >/dev/null 2>&1
    fi
}
trap _cleanup_gdrive_mount HUP TERM EXIT
```

---

## دستورات کاربردی روزمره

* **ورود سریع به فضای گوگل درایو:**
  ```bash
  cddrive
  ```
* **بررسی وضعیت سلامت اتصال:**
  ```bash
  ~/cloudshell-gdrive-sync/health_check.sh
  ```
* **مشاهده لاگ‌های اتصال و واچ‌داگ:**
  ```bash
  tail -f ~/cloudshell-gdrive-sync/rclone_mount.log
  tail -f ~/cloudshell-gdrive-sync/health_check.log
  ```
* **قطع اتصال دستی:**
  ```bash
  ~/cloudshell-gdrive-sync/unmount.sh
  ```

---

## عیب‌یابی (Troubleshooting)

### انقضای توکن گوگل (`invalid_grant`):
دستور `rclone config reconnect gdrive:` را اجرا کرده و کد احراز هویت جدید را از مرورگر دریافت و جایگزین کنید.

### قفل شدن یا قطع ارتباط نقطه اتصال:
تنها کافی است اسکریپت زیر را اجرا کنید تا فرایند خودترمیمی بلافاصله دیمن‌های ناقص را بسته و مجدداً پوشه را مانت کند:
```bash
~/cloudshell-gdrive-sync/health_check.sh
```

---

## مجوز (License)
این پروژه تحت لایسنس MIT منتشر شده است.