#!/usr/bin/env bash
set -Eeuo pipefail

REPO_NAME="${1:-my-private-app}"
PROJECT_DIR="${HOME}/${REPO_NAME}"

echo "==> ۱. بررسی دسترسی به GitHub CLI..."
if ! gh auth status >/dev/null 2>&1; then
    echo "لطفاً ابتدا لاگین گیت‌هاب را تکمیل کنید:"
    gh auth login -w -p https
fi

echo "==> ۲. ایجاد ساختار استاندارد پروژه در: ${PROJECT_DIR}"
mkdir -p "${PROJECT_DIR}"/{src,tests,.vscode,.github/workflows}
cd "${PROJECT_DIR}"

git init -b main

# تنظیم مشخصات پیش‌فرض گیت در صورت عدم تنظیم قبلی
git config user.name "$(gh api user --jq .name || echo 'Developer')"
git config user.email "$(gh api user --jq .email || echo 'dev@example.com')"

# ایجاد .gitignore استاندارد
cat << 'GITIGNORE' > .gitignore
__pycache__/
*.pyc
*.pyo
*.pyd
.env
.venv/
env/
dist/
build/
*.log
.DS_Store
node_modules/
GITIGNORE

# ایجاد README حرفه‌ای
cat << README > README.md
# ${REPO_NAME}

مخزن خصوصی مدیریت و توسعه پروژه در Cloud Shell.

## ساختار پروژه
- \`src/\`: کدهای اصلی برنامه
- \`tests/\`: تست‌های واحد و یکپارچگی
- \`.vscode/\`: تنظیمات اجرای مستقیم کدها از طریق ادیتور

## نحوه اجرا
برای اجرای برنامه، فایل مورد نظر را در ادیتور باز کرده و کلید **F5** را فشار دهید یا از منوی **Run and Debug** گزینه **Run Current File** را انتخاب کنید.
README

# نمونه کد اجرایی در src/main.py
cat << 'CODE' > src/main.py
#!/usr/bin/env python3
import sys

def main():
    print("برنامه با موفقیت از محیط ادیتور اجرا شد!")
    print(f"نسخه پایتون: {sys.version.split()[0]}")

if __name__ == "__main__":
    main()
CODE
chmod +x src/main.py

# پیکربندی VS Code جهت اجرای مستقیم با کلید میانبر و دکمه Play ادیتور
cat << 'LAUNCH' > .vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Run Current File",
            "type": "python",
            "request": "launch",
            "program": "${file}",
            "console": "integratedTerminal"
        }
    ]
}
LAUNCH

cat << 'TASKS' > .vscode/tasks.json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Run main.py",
            "type": "shell",
            "command": "python3 ${workspaceFolder}/src/main.py",
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "presentation": {
                "reveal": "always",
                "panel": "new"
            }
        }
    ]
}
TASKS

# نمونه اکشن GitHub برای تست خودکار CI
cat << 'WORKFLOW' > .github/workflows/ci.yml
name: CI Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
      - name: Run entrypoint
        run: python src/main.py
WORKFLOW

echo "==> ۳. کامیت و ثبت تغییرات محلی..."
git add .
git commit -m "feat: initial professional repository structure"

echo "==> ۴. ساخت مخزن Private در گیت‌هاب و ارسال کدها..."
gh repo create "${REPO_NAME}" --private --source=. --remote=origin --push

echo "==> ۵. باز کردن محیط در ادیتور Cloud Shell..."
if command -v cloudshell >/dev/null 2>&1; then
    cloudshell workspace "${PROJECT_DIR}"
    cloudshell edit "${PROJECT_DIR}/src/main.py"
fi

echo "=========================================================="
echo "پروژه ${REPO_NAME} با موفقیت ساخته شد و در گیت‌هاب پرایویت قرار گرفت."
echo "مسیر پروژه: ${PROJECT_DIR}"
echo "=========================================================="
