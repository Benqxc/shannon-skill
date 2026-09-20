#!/usr/bin/env bash
# setup-shannon.sh - Install or update the Shannon pentester
#
# Usage:
#   bash scripts/setup-shannon.sh [OPTIONS] [SHANNON_HOME]
#
# Options:
#   -r, --repo URL       Shannon git repository URL
#                        (default: https://github.com/KeygraphHQ/shannon.git)
#   -b, --branch NAME    Branch, tag, or commit to check out (default: default branch)
#   -h, --help           Show this help and exit
#
# Environment:
#   SHANNON_HOME         Install directory (default: $HOME/shannon)
#   SHANNON_REPO         Same as --repo
#   SHANNON_BRANCH       Same as --branch
#
# Requirements: bash, git, docker (daemon running). Windows: Git Bash or WSL.
set -euo pipefail

REPO_URL="${SHANNON_REPO:-https://github.com/KeygraphHQ/shannon.git}"
BRANCH="${SHANNON_BRANCH:-}"
SHANNON_HOME_ARG=""

usage() {
  sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
  case "$1" in
    -r|--repo)   REPO_URL="${2:?missing value for $1}"; shift 2 ;;
    -b|--branch) BRANCH="${2:?missing value for $1}"; shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    -*) echo "Unknown option: $1 (see --help)" >&2; exit 2 ;;
    *) SHANNON_HOME_ARG="$1"; shift ;;
  esac
done

if [ -n "$SHANNON_HOME_ARG" ]; then
  SHANNON_HOME="$SHANNON_HOME_ARG"
else
  SHANNON_HOME="${SHANNON_HOME:-$HOME/shannon}"
fi

fail() { echo "ERROR: $*" >&2; exit 1; }
warn() { echo "WARNING: $*" >&2; }

echo "Shannon Setup"
echo "============="

# --- Preflight ---------------------------------------------------------------
command -v git >/dev/null 2>&1 || fail "git is not installed. Install git first: https://git-scm.com/downloads"
command -v docker >/dev/null 2>&1 || fail "docker is not installed. Install Docker Desktop: https://docker.com/products/docker-desktop"
echo "OK: git ($(git --version))"
echo "OK: docker CLI ($(docker --version 2>/dev/null | head -1))"

if ! docker info >/dev/null 2>&1; then
  fail "docker is installed but the daemon is not reachable. Start Docker Desktop (or dockerd) and retry."
fi
echo "OK: docker daemon reachable"

# Destination must be writable (or creatable via a writable parent)
if [ -e "$SHANNON_HOME" ]; then
  [ -d "$SHANNON_HOME" ] || fail "$SHANNON_HOME exists and is not a directory."
  [ -w "$SHANNON_HOME" ] || fail "$SHANNON_HOME is not writable."
else
  PARENT="$(dirname "$SHANNON_HOME")"
  [ -d "$PARENT" ] || fail "parent directory does not exist: $PARENT"
  [ -w "$PARENT" ] || fail "parent directory is not writable: $PARENT"
fi

# --- Clone or update ---------------------------------------------------------
if [ -d "$SHANNON_HOME/.git" ]; then
  echo "Found existing git checkout at $SHANNON_HOME"
  CURRENT_URL="$(git -C "$SHANNON_HOME" remote get-url origin 2>/dev/null || true)"
  if [ -n "$CURRENT_URL" ] && [ "$CURRENT_URL" != "$REPO_URL" ]; then
    warn "existing origin ($CURRENT_URL) differs from requested ($REPO_URL); keeping existing checkout."
  else
    echo "Updating (git pull --ff-only)..."
    if ! git -C "$SHANNON_HOME" pull --ff-only; then
      fail "git pull failed. Resolve conflicts in $SHANNON_HOME or back it up and re-run."
    fi
  fi
elif [ -e "$SHANNON_HOME/shannon" ] || [ -n "$(ls -A "$SHANNON_HOME" 2>/dev/null)" ]; then
  fail "$SHANNON_HOME exists but is not a Shannon git checkout. Move it aside (or pass another directory) and re-run."
else
  echo "Cloning Shannon to $SHANNON_HOME..."
  if [ -n "$BRANCH" ]; then
    git clone --branch "$BRANCH" "$REPO_URL" "$SHANNON_HOME" \
      || fail "git clone failed. Check network access and the repo URL/branch."
  else
    git clone "$REPO_URL" "$SHANNON_HOME" \
      || fail "git clone failed. Check network access and the repo URL."
  fi
  echo "Shannon cloned successfully."
fi

if [ ! -x "$SHANNON_HOME/shannon" ]; then
  warn "$SHANNON_HOME/shannon is missing or not executable; the checkout may be incomplete."
else
  echo "OK: $SHANNON_HOME/shannon present"
fi

# --- API credentials (presence check only; validity is not tested) -----------
echo ""
echo "API Credentials:"
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  echo "OK: ANTHROPIC_API_KEY is set"
elif [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
  echo "OK: CLAUDE_CODE_OAUTH_TOKEN is set"
elif [ "${CLAUDE_CODE_USE_BEDROCK:-}" = "1" ]; then
  echo "OK: AWS Bedrock mode enabled (credentials not validated)"
elif [ "${CLAUDE_CODE_USE_VERTEX:-}" = "1" ]; then
  echo "OK: Google Vertex AI mode enabled (credentials not validated)"
else
  warn "no AI credentials detected. Set one of:"
  echo "   export ANTHROPIC_API_KEY=sk-ant-..."
  echo "   export CLAUDE_CODE_OAUTH_TOKEN=..."
  echo "   export CLAUDE_CODE_USE_BEDROCK=1   (+ AWS credentials)"
  echo "   export CLAUDE_CODE_USE_VERTEX=1    (+ GCP service account)"
fi

echo ""
echo "Recommended: export CLAUDE_CODE_MAX_OUTPUT_TOKENS=64000"
echo ""
echo "Shannon is ready at: $SHANNON_HOME"
echo "Run a pentest:  cd $SHANNON_HOME && ./shannon start URL=http://localhost:3000 REPO=myapp"
