#!/usr/bin/env bash
# ==============================================================================
# Gunny 9.2 - Push All Repositories to GitHub in 1-Click
# Usage:
#   ./push_all_to_github.sh <YOUR_GITHUB_USERNAME_OR_ORG> [PROTOCOL: https|ssh]
# Example:
#   ./push_all_to_github.sh myaccount
# ==============================================================================

set -e

GITHUB_USER="$1"
PROTOCOL="${2:-https}"

if [ -z "${GITHUB_USER}" ]; then
    echo "ERROR: Please specify your GitHub username or organization."
    echo "Usage: ./push_all_to_github.sh <YOUR_GITHUB_USERNAME> [https|ssh]"
    exit 1
fi

get_repo_url() {
    local repo_name="$1"
    if [ "${PROTOCOL}" = "ssh" ]; then
        echo "git@github.com:${GITHUB_USER}/${repo_name}.git"
    else
        echo "https://github.com/${GITHUB_USER}/${repo_name}.git"
    fi
}

push_repo() {
    local repo_name="$1"
    local repo_dir="$2"
    local repo_url=$(get_repo_url "${repo_name}")

    if [ -d "${repo_dir}/.git" ]; then
        echo "--------------------------------------------------"
        echo "[PUSHING] ${repo_name} (${repo_dir}) -> ${repo_url}..."
        git -C "${repo_dir}" remote remove origin 2>/dev/null || true
        git -C "${repo_dir}" remote add origin "${repo_url}"
        git -C "${repo_dir}" branch -M master
        git -C "${repo_dir}" push -u origin master || echo "Warning: Push failed for ${repo_name}. Please make sure the repo exists on GitHub."
    else
        echo "[SKIP] ${repo_dir} is not a git repository."
    fi
}

# Push Root
push_repo "gunny92-root" "."

# Push WebPortal & macOS Client
push_repo "gunny92-webportal" "WebPortal"
push_repo "gunny92-macos-client" "macOS_Client"

# Push Gunny92 Submodules
push_repo "gunny92-server" "Gunny92/Server"
push_repo "gunny92-flash" "Gunny92/Flash"
push_repo "gunny92-request" "Gunny92/Request"
push_repo "gunny92-launcher" "Gunny92/launcher_base"
push_repo "gunny92-flashbase" "Gunny92/flashbaseSrc"
push_repo "gunny92-gamesrc" "Gunny92/gameSrc"
push_repo "gunny92-db" "Gunny92_DB"
push_repo "gunny92-resource" "Gunny92/Resource.Server"

echo "=================================================="
echo "All repositories pushed successfully to GitHub!"
echo "=================================================="
