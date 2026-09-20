#!/usr/bin/env bash
# sync.sh - Deploy the shannon skill to host skill directories
#
# Usage:
#   bash scripts/sync.sh [--target DIR]... [--list]
#
# Default targets:
#   $HOME/.claude/skills/shannon
#   $HOME/.agents/skills/shannon
#   $HOME/.codex/skills/shannon
#
# Pass --target DIR one or more times to sync only those directories.
# Use --list to print the default targets and exit.
# Works with cp only (no rsync required).
set -euo pipefail

# Resolve the real repo root even when invoked through a symlink.
SELF="${BASH_SOURCE[0]}"
while [ -L "$SELF" ]; do
  SELF="$(readlink "$SELF")"
  case "$SELF" in
    /*) ;;
    *) SELF="$(dirname "${BASH_SOURCE[0]}")/$SELF" ;;
  esac
done
SRC="$(cd "$(dirname "$SELF")/.." && pwd)"
echo "Source: $SRC"

DEFAULT_TARGETS=(
  "$HOME/.claude/skills/shannon"
  "$HOME/.agents/skills/shannon"
  "$HOME/.codex/skills/shannon"
)

TARGETS=()
LIST_ONLY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --target) [ $# -ge 2 ] || { echo "ERROR: --target needs a directory" >&2; exit 2; }
      TARGETS+=("$2"); shift 2 ;;
    --list) LIST_ONLY=1; shift ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "ERROR: unknown argument: $1 (see --help)" >&2; exit 2 ;;
  esac
done

if [ "$LIST_ONLY" -eq 1 ]; then
  printf '%s\n' "${DEFAULT_TARGETS[@]}"
  exit 0
fi

if [ "${#TARGETS[@]}" -eq 0 ]; then
  TARGETS=("${DEFAULT_TARGETS[@]}")
fi

# --- Preflight: validate sources before touching any target ------------------
[ -f "$SRC/SKILL.md" ] || { echo "ERROR: SKILL.md not found in $SRC" >&2; exit 1; }
[ -r "$SRC/SKILL.md" ] || { echo "ERROR: SKILL.md is not readable" >&2; exit 1; }

shopt -s nullglob
SRC_SCRIPTS=("$SRC"/scripts/*.sh)
shopt -u nullglob

# --- Sync --------------------------------------------------------------------
ok=0
failed=0
for t in "${TARGETS[@]}"; do
  case "$t" in
    ""|"/") echo "SKIP: refusing dangerous target '$t'" >&2; failed=$((failed+1)); continue ;;
  esac
  echo ""
  echo "--- Syncing to $t ---"
  if ! mkdir -p "$t/scripts"; then
    echo "FAILED: cannot create $t/scripts (permission?)" >&2
    failed=$((failed+1)); continue
  fi
  if ! cp "$SRC/SKILL.md" "$t/"; then
    echo "FAILED: cannot copy SKILL.md to $t" >&2
    failed=$((failed+1)); continue
  fi
  for s in "${SRC_SCRIPTS[@]}"; do
    if ! cp "$s" "$t/scripts/"; then
      echo "FAILED: cannot copy $(basename "$s") to $t/scripts" >&2
      failed=$((failed+1)); continue 2
    fi
  done
  echo "  Deployed to $t"
  ok=$((ok+1))
done

echo ""
echo "Sync complete: $ok ok, $failed failed."
[ "$failed" -eq 0 ]
