#!/usr/bin/env bash
# ==============================================================================
# Gunny 9.2 - Automated Multi-Repository Initialization Script
# Usage:
#   ./init.sh [GITHUB_USERNAME_OR_ORG] [PROTOCOL: https|ssh]
# Examples:
#   ./init.sh myuser
#   ./init.sh myuser ssh
# ==============================================================================

set -e

GITHUB_USER="${1:-YOUR_USERNAME}"
PROTOCOL="${2:-https}"

echo "======================================================================"
echo " Gunny 9.2 - Cloning and Assembling Full Source Code"
echo " Target GitHub Account: ${GITHUB_USER}"
echo " Protocol:              ${PROTOCOL}"
echo "======================================================================"

if [ "${GITHUB_USER}" = "YOUR_USERNAME" ]; then
    echo "WARNING: Using default placeholder 'YOUR_USERNAME'."
    echo "To clone from your own account, run: ./init.sh <your_github_username>"
    echo ""
fi

get_repo_url() {
    local repo_name="$1"
    if [ "${PROTOCOL}" = "ssh" ]; then
        echo "git@github.com:${GITHUB_USER}/${repo_name}.git"
    else
        echo "https://github.com/${GITHUB_USER}/${repo_name}.git"
    fi
}

clone_or_pull() {
    local repo_name="$1"
    local dest_dir="$2"
    local repo_url=$(get_repo_url "${repo_name}")

    if [ -d "${dest_dir}/.git" ]; then
        echo "[EXISTS] ${dest_dir} already initialized. Pulling latest..."
        git -C "${dest_dir}" pull || echo "Warning: Pull failed for ${dest_dir}, skipping."
    else
        echo "[CLONING] ${repo_name} -> ${dest_dir}..."
        mkdir -p "$(dirname "${dest_dir}")"
        git clone "${repo_url}" "${dest_dir}" || {
            echo "ERROR: Failed to clone ${repo_url} into ${dest_dir}"
            echo "Please check if repository exists and permissions are granted."
        }
    fi
}

# 1. Clone top-level subdirectories
clone_or_pull "gunny92-webportal" "WebPortal"
clone_or_pull "gunny92-macos-client" "macOS_Client"

# 2. Ensure Gunny92 directory exists
mkdir -p Gunny92

# 3. Clone Gunny92 core submodules
clone_or_pull "gunny92-server" "Gunny92/Server"
clone_or_pull "gunny92-flash" "Gunny92/Flash"
clone_or_pull "gunny92-request" "Gunny92/Request"
clone_or_pull "gunny92-resource" "Gunny92/Resource.Server"
clone_or_pull "gunny92-gamesrc" "Gunny92/gameSrc"
clone_or_pull "gunny92-flashbase" "Gunny92/flashbaseSrc"
clone_or_pull "gunny92-launcher" "Gunny92/launcher_base"
clone_or_pull "gunny92-web" "Gunny92/web_temp"

# Move web_temp contents into Gunny92 if web_temp was cloned
if [ -d "Gunny92/web_temp" ]; then
    echo "[SYNC] Moving web components into Gunny92/..."
    cp -rn Gunny92/web_temp/* Gunny92/ 2>/dev/null || true
    rm -rf Gunny92/web_temp
fi

# 4. Clone and assemble Database backups
clone_or_pull "gunny92-db" "Gunny92/db_temp"
if [ -d "Gunny92/db_temp" ]; then
    echo "[SYNC] Moving database backups into Gunny92/..."
    cp -rn Gunny92/db_temp/* Gunny92/ 2>/dev/null || true
    rm -rf Gunny92/db_temp
fi

# 5. Extract admin.bak.zip if admin.bak doesn't exist
if [ ! -f "Gunny92/admin.bak" ] && [ -f "Gunny92/admin.bak.zip" ]; then
    echo "[EXTRACT] Unzipping Gunny92/admin.bak.zip..."
    if command -v unzip >/dev/null 2>&1; then
        unzip -o "Gunny92/admin.bak.zip" -d "Gunny92"
    elif command -v powershell.exe >/dev/null 2>&1; then
        powershell.exe -Command "Expand-Archive -Path 'Gunny92\admin.bak.zip' -DestinationPath 'Gunny92' -Force"
    fi
fi

# 6. Windows Junction setup (if running under Windows / MSYS / Git Bash)
if command -v cmd.exe >/dev/null 2>&1; then
    TARGET_PATH="$(pwd -W 2>/dev/null || pwd)/Gunny92"
    TARGET_PATH="${TARGET_PATH//\//\\}"
    if [ ! -d "C:\\Gunny92" ]; then
        echo "[JUNCTION] Creating directory junction C:\\Gunny92 -> ${TARGET_PATH}..."
        cmd.exe /c "mklink /J C:\Gunny92 \"${TARGET_PATH}\"" 2>/dev/null || echo "Note: Junction creation requires admin rights or C:\Gunny92 already exists."
    fi
fi

echo "======================================================================"
echo " Project Initialization Complete!"
echo " Next step: Read README.md for instructions on running the project."
echo "======================================================================"
