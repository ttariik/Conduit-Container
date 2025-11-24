#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -lt 2 ]]; then
  cat <<'USAGE'
Usage: scripts/bootstrap-sources.sh <frontend_git_url> <backend_git_url> [<branch>]

Clones the provided Conduit frontend and backend repositories into the local
workspace. Run this script once after forking the upstream projects.

Examples:
  scripts/bootstrap-sources.sh git@github.com:me/conduit-frontend.git \
                               git@github.com:me/conduit-backend.git
  scripts/bootstrap-sources.sh https://github.com/me/conduit-frontend.git \
                               https://github.com/me/conduit-backend.git develop
USAGE
  exit 64
fi

FRONTEND_URL="$1"
BACKEND_URL="$2"
BRANCH="${3:-main}"

clone_or_pull() {
  local target_dir="$1"
  local git_url="$2"
  local branch="$3"

  if [[ -d "${target_dir}/.git" ]]; then
    echo "Updating ${target_dir}..."
    git -C "${target_dir}" fetch origin "${branch}"
    git -C "${target_dir}" checkout "${branch}"
    git -C "${target_dir}" pull --ff-only origin "${branch}"
  else
    echo "Cloning ${git_url} into ${target_dir}..."
    git clone --branch "${branch}" --depth 1 "${git_url}" "${target_dir}"
  fi
}

clone_or_pull "${REPO_ROOT}/frontend" "${FRONTEND_URL}" "${BRANCH}"
clone_or_pull "${REPO_ROOT}/backend" "${BACKEND_URL}" "${BRANCH}"

echo "✅ Frontend and backend sources are ready."

