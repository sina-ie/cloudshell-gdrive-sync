#!/usr/bin/env bash
set -Eeuo pipefail

REPO_NAME="${1:-my-private-app}"
PROJECT_DIR="${HOME}/${REPO_NAME}"

echo "==> 1. Verifying GitHub CLI authentication..."
if ! gh auth status >/dev/null 2>&1; then
    echo "Please complete GitHub authentication first:"
    gh auth login -w -p https
fi

echo "==> 2. Creating standard project scaffold at: ${PROJECT_DIR}"
mkdir -p "${PROJECT_DIR}"/{src,tests,.vscode,.github/workflows}
cd "${PROJECT_DIR}"

git init -b main

# Configure Git user identity if not already set
if [ -z "$(git config --get user.name || true)" ]; then
    GH_NAME="$(gh api user --jq '.name // empty' 2>/dev/null || true)"
    git config user.name "${GH_NAME:-Developer}"
fi
if [ -z "$(git config --get user.email || true)" ]; then
    GH_EMAIL="$(gh api user --jq '.email // empty' 2>/dev/null || true)"
    git config user.email "${GH_EMAIL:-developer@example.com}"
fi

# Create standard .gitignore
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

# Create project README
cat << README > README.md
# ${REPO_NAME}

Private workspace repository developed and managed within Google Cloud Shell.

## Structure
- \`src/\`: Core application source files
- \`tests/\`: Unit and integration test suites
- \`.vscode/\`: Editor execution and debugging configurations

## Execution
Open the target file in Cloud Shell Editor and press **F5**, or navigate to **Run and Debug** and choose **Run Current File**.
README

# Generate boilerplate entrypoint in src/main.py
cat << 'CODE' > src/main.py
#!/usr/bin/env python3
import sys

def main():
    print("Application executed successfully from the Cloud Shell editor environment!")
    print(f"Python version: {sys.version.split()[0]}")

if __name__ == "__main__":
    main()
CODE
chmod +x src/main.py

# Configure VS Code debugging and tasks for instant execution
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

# GitHub Actions CI workflow
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

echo "==> 3. Staging and committing initial project structure..."
git add .
git commit -m "feat: initial professional repository structure"

echo "==> 4. Creating private GitHub repository and pushing codebase..."
gh repo create "${REPO_NAME}" --private --source=. --remote=origin --push

echo "==> 5. Launching workspace in Cloud Shell Editor..."
if command -v cloudshell >/dev/null 2>&1; then
    cloudshell workspace "${PROJECT_DIR}"
    cloudshell edit "${PROJECT_DIR}/src/main.py"
fi

echo "=========================================================="
echo "Project '${REPO_NAME}' successfully initialized and published to private GitHub repository."
echo "Workspace location: ${PROJECT_DIR}"
echo "=========================================================="
