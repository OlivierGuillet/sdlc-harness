#!/usr/bin/env bash
# Add the SDLC harness to an iOS project.
#
#   templates/ios-setup.sh [project-dir] [--replace-skills] [--no-cc-sdd]
#
# - merges templates/ios.settings.json into <project>/.claude/settings.json
#   (existing file backed up as settings.json.bak-<timestamp>, which is added
#   to the project's .gitignore)
# - creates the .harness marker, docs/specs/ and docs/adr/
# - exports Xcode's agent skills into <project>/.claude/skills
#   (xcrun agent skills export)
# - offers to install cc-sdd skills (npx cc-sdd@latest --claude-skills --kiro-dir docs)
# - installs the harness CLAUDE.md (templates/install-claude-md.sh), replacing
#   the one cc-sdd writes (backed up as CLAUDE.md.bak-<timestamp>)

set -euo pipefail

PROJECT="."
REPLACE=""
CC_SDD=1
for arg in "$@"; do
  case "$arg" in
    --replace-skills) REPLACE="--replace-existing" ;;
    --no-cc-sdd) CC_SDD=0 ;;
    -h|--help) sed -n '2,16p' "$0"; exit 0 ;;
    *) PROJECT="$arg" ;;
  esac
done

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 1; }
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT="$(cd "$PROJECT" && pwd -P)"
. "$HERE/lib.sh"
echo "project: $PROJECT"

# 1. Project settings
mkdir -p "$PROJECT/.claude"
settings="$PROJECT/.claude/settings.json"
if [ -f "$settings" ]; then
  cp "$settings" "$settings.bak-$(date +%Y%m%d-%H%M%S)"
  jq -s '.[0] as $a | .[1] as $b | ($a * $b) | .permissions.allow = (($a.permissions.allow // []) + ($b.permissions.allow // []) | unique)' \
    "$settings" "$HERE/ios.settings.json" > "$settings.tmp"
  mv "$settings.tmp" "$settings"
  echo "merged : .claude/settings.json (backup kept)"
  git_ignore "$PROJECT" '.claude/settings.json.bak-*'
else
  cp "$HERE/ios.settings.json" "$settings"
  echo "created: .claude/settings.json"
fi

# 2. Marker and docs folders
touch "$PROJECT/.harness"
mkdir -p "$PROJECT/docs/specs" "$PROJECT/docs/adr"
echo "created: .harness, docs/specs/, docs/adr/"

# 3. Xcode agent skills
if xcrun --find agent >/dev/null 2>&1 || xcrun agent --help >/dev/null 2>&1; then
  mkdir -p "$PROJECT/.claude/skills"
  # shellcheck disable=SC2086
  xcrun agent skills export --output-dir "$PROJECT/.claude/skills" $REPLACE
  echo "exported Xcode skills into .claude/skills"
else
  echo "warning: 'xcrun agent' not available (requires Xcode 27); skipped skills export" >&2
fi

# 4. cc-sdd
cc_sdd_failed=0
if [ "$CC_SDD" -eq 1 ] && [ ! -d "$PROJECT/.claude/skills/kiro-spec-init" ]; then
  printf 'Install cc-sdd skills now (npx cc-sdd@latest --claude-skills --kiro-dir docs)? [y/N] '
  read -r answer || answer=""
  case "$answer" in
    y|Y|yes)
      if ! (cd "$PROJECT" && npx cc-sdd@latest --claude-skills --kiro-dir docs); then
        cc_sdd_failed=1
        echo "warning: cc-sdd install failed; continuing with the rest of the setup" >&2
      fi
      ;;
    *) echo "skipped: run 'npx cc-sdd@latest --claude-skills --kiro-dir docs' in the project later" ;;
  esac
fi

# 5. Project CLAUDE.md (after cc-sdd, which writes its own)
"$HERE/install-claude-md.sh" "$PROJECT"

if [ "$cc_sdd_failed" -eq 1 ]; then
  echo "error: cc-sdd was not installed. Fix the cause, then run in the project:" >&2
  echo "  npx cc-sdd@latest --claude-skills --kiro-dir docs && \"$HERE/install-claude-md.sh\" ." >&2
  exit 1
fi

echo "done. Commit .harness, CLAUDE.md, .gitignore, .claude/settings.json, .claude/skills/ and docs/ with the project."
echo "Start Claude Code from $PROJECT so the project skills and hooks are loaded."
