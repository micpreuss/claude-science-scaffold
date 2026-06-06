#!/usr/bin/env bash
#
# install.sh — inject this scaffold's .claude/ folder into a target project.
#
# Usage:
#   ./install.sh <target-project-dir> [--merge | --force] [--dry-run]
#
# Modes:
#   (default)   Copy .claude/ into the target. Aborts if the target already
#               has a .claude/ (so you never clobber existing work by accident).
#   --merge     Add only files that don't exist yet; never overwrite. Use this
#               to top up an existing .claude/ with the scaffold's skills.
#   --force     Overwrite. The existing .claude/ is backed up to
#               .claude.bak.<timestamp>/ first.
#   --dry-run   Print what would happen; change nothing.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/.claude"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
info() { printf '%s\n' "$*"; }

[[ -d "$SRC" ]] || die "no .claude/ next to install.sh (looked in $SRC)"

TARGET=""
MODE="copy"
DRY=0
for arg in "$@"; do
  case "$arg" in
    --merge)   MODE="merge" ;;
    --force)   MODE="force" ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    -*)        die "unknown flag: $arg" ;;
    *)         TARGET="$arg" ;;
  esac
done

[[ -n "$TARGET" ]] || die "missing target project dir. Usage: ./install.sh <dir> [--merge|--force]"
[[ -d "$TARGET" ]] || die "target is not a directory: $TARGET"

DEST="$TARGET/.claude"
run() { if [[ "$DRY" -eq 1 ]]; then info "DRY: $*"; else eval "$@"; fi; }

if [[ ! -e "$DEST" ]]; then
  info "Installing .claude/ -> $DEST"
  run "cp -R \"$SRC\" \"$DEST\""
elif [[ "$MODE" == "merge" ]]; then
  info "Merging (no overwrite) .claude/ -> $DEST"
  run "mkdir -p \"$DEST\""
  # BSD/macOS and GNU cp both support -n (no-clobber).
  run "cp -Rn \"$SRC/.\" \"$DEST/\""
elif [[ "$MODE" == "force" ]]; then
  BAK="$TARGET/.claude.bak.$(date +%Y%m%d-%H%M%S)"
  info "Backing up existing $DEST -> $BAK, then overwriting"
  run "mv \"$DEST\" \"$BAK\""
  run "cp -R \"$SRC\" \"$DEST\""
else
  die "$DEST already exists. Re-run with --merge (add new files only) or --force (overwrite with backup)."
fi

info "Done. Next: open the project in Claude and run /prime, then /create-rules."
