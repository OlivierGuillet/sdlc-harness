#!/usr/bin/env bash
# Link the harness dotfiles into ~/.claude.
#
#   dotfiles/install.sh [--dry-run]
#
# - ~/.claude/CLAUDE.md     -> dotfiles/CLAUDE.md (symlink)
# - ~/.claude/settings.json -> dotfiles/settings.generated.json (symlink)
#
# settings.generated.json is git-ignored. It is built from dotfiles/settings.json
# (versioned, portable) by replacing ${HARNESS_ROOT} with this clone's path and
# deep-merging it over your existing settings, so personal keys (model, theme,
# permissions, plugins enabled with /plugin...) are kept. Keys from the versioned
# template win.
#
# Existing files are backed up to ~/.claude/backups/harness-<timestamp>/.
# ~/.claude.json is never read nor written.

set -euo pipefail

DRY_RUN=0
[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

run() {
  if [ "$DRY_RUN" -eq 1 ]; then printf '[dry-run] %s\n' "$*"; else "$@"; fi
}

command -v jq >/dev/null 2>&1 || { echo "error: jq is required (brew install jq)" >&2; exit 1; }

HARNESS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DOTFILES="$HARNESS_ROOT/dotfiles"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
GENERATED="$DOTFILES/settings.generated.json"
BACKUP_DIR="$CLAUDE_DIR/backups/harness-$(date +%Y%m%d-%H%M%S)"

# Hard guard: this script only ever touches these two targets.
TARGETS=("$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/settings.json")
for t in "${TARGETS[@]}"; do
  case "$t" in
    "$HOME/.claude.json") echo "refusing to touch $t" >&2; exit 1 ;;
  esac
done

echo "harness root : $HARNESS_ROOT"
echo "claude dir   : $CLAUDE_DIR"

run mkdir -p "$CLAUDE_DIR"

backup() { # backup <target> <expected symlink source>
  local target="$1" source="$2"
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    return 0 # already our link
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    run mkdir -p "$BACKUP_DIR"
    run cp -P "$target" "$BACKUP_DIR/"
    echo "backed up    : $target -> $BACKUP_DIR/"
  fi
}

# 1. Build settings.generated.json
template="$(sed "s|\${HARNESS_ROOT}|$HARNESS_ROOT|g" "$DOTFILES/settings.json")"
base='{}'
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  # Follows the symlink if it already points to a previous generated file.
  base="$(cat "$CLAUDE_DIR/settings.json")"
elif [ -f "$GENERATED" ]; then
  base="$(cat "$GENERATED")"
fi
merged="$(jq -n --argjson a "$base" --argjson b "$template" '$a * $b')"

backup "$CLAUDE_DIR/settings.json" "$GENERATED"
backup "$CLAUDE_DIR/CLAUDE.md" "$DOTFILES/CLAUDE.md"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "[dry-run] would write $GENERATED:"
  printf '%s\n' "$merged"
else
  tmp="$(mktemp "$DOTFILES/.settings.XXXXXX")"
  printf '%s\n' "$merged" > "$tmp"
  mv "$tmp" "$GENERATED"
fi

# 2. Symlinks (replace files only after they were backed up above)
run ln -sfn "$DOTFILES/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
run ln -sfn "$GENERATED" "$CLAUDE_DIR/settings.json"

echo "linked       : $CLAUDE_DIR/CLAUDE.md -> $DOTFILES/CLAUDE.md"
echo "linked       : $CLAUDE_DIR/settings.json -> $GENERATED"

# 3. Versioned git hooks for this repository (pre-commit runs plugin validation)
if git -C "$HARNESS_ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  run git -C "$HARNESS_ROOT" config core.hooksPath .githooks
  echo "git hooks    : core.hooksPath=.githooks"
fi
echo
echo "Next: claude plugin marketplace add \"$HARNESS_ROOT\""
echo "      claude plugin install harness-sdlc@harness"
echo "      claude plugin install superpowers@claude-plugins-official"
