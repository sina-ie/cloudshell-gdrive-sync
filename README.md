# Cloud Shell & Google Drive Unified Storage (FUSE VFS)

سیستم یکپارچه‌سازی بلادرنگ و دوطرفه بین گوگل کلود شل و گوگل درایو مبتنی بر FUSE3 و rclone VFS.

## ویژگی‌ها
- **همگام‌سازی بلادرنگ دوطرفه:** بدون نیاز به اجرای دستی اسکریپت‌های sync یا pull.
- **کش هوشمند VFS:** امکان باز کردن و ویرایش مستقیم فایل‌ها در ادیتور Cloud Shell.
- **مدیریت نشست خودکار:** اتصال خودکار هنگام ورود به شل (`mount.sh`) و قطع امن هنگام خروج (`unmount.sh`).

## نحوه استفاده

### نقطه اتصال (Mount Point)
مسیر کاری اصلی:
```bash
cd ~/drive_workspace
```

### اتصال دستی
```bash
~/cloudshell-gdrive-sync/mount.sh
```

### قطع اتصال امن
```bash
~/cloudshell-gdrive-sync/unmount.sh
```

### لاگ‌ها
لاگ‌های مربوط به فرایند مانت در مسیر زیر ذخیره می‌شوند:
```bash
tail -f ~/cloudshell-gdrive-sync/rclone_mount.log
```
