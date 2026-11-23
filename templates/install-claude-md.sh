#!/usr/bin/env bash
# Install the harness CLAUDE.md into a project.
#
#   templates/install-claude-md.sh [project-dir]
#
# - copies templates/project.CLAUDE.md to <project>/CLAUDE.md
# - an existing CLAUDE.md that differs from the template (cc-sdd's, a
#   hand-written one, or a harness one edited by hand) is first moved to
#   CLAUDE.md.bak-<timestamp>; nothing is ever overwritten without a backup
# - does nothing when the file is already identical to the template
# - refuses to run in a directory without the .harness marker
# - adds CLAUDE.md.bak-* to the project's .gitignore when it leaves a backup
#
# Run it again after `npx cc-sdd`, which rewrites CLAUDE.md with its own workflow.

set -euo pipefail

case "${1:-}" in
  -h|--help) sed -n '2,14p' "$0"; exit 0 ;;
esac

PROJECT="${1:-.}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

TEMPLATE="$HERE/project.CLAUDE.md"
. "$HERE/lib.sh"

[ -d "$PROJECT" ] || { echo "error: no such directory: $PROJECT" >&2; exit 1; }
[ -f "$TEMPLATE" ] || { echo "error: template not found: $TEMPLATE" >&2; exit 1; }
[ -f "$PROJECT/.harness" ] || {
  echo "error: $PROJECT is not a harness project (no .harness file). Run 'touch .harness' there first." >&2
  exit 1
}

target="$PROJECT/CLAUDE.md"
action="created"
if [ -e "$target" ] || [ -L "$target" ]; then
  if [ -f "$target" ] && [ ! -L "$target" ] && cmp -s "$TEMPLATE" "$target"; then
    echo "up to date: CLAUDE.md"
    exit 0
  fi
  stamp="$(date +%Y%m%d-%H%M%S)"
  backup="$target.bak-$stamp"
  n=1
  while [ -e "$backup" ] || [ -L "$backup" ]; do
    n=$((n + 1))
    backup="$target.bak-$stamp-$n"
  done
  mv "$target" "$backup"
  action="replaced"
  echo "backup : $(basename "$backup")"
  git_ignore "$PROJECT" 'CLAUDE.md.bak-*'
fi

cp "$TEMPLATE" "$target"
echo "$action: CLAUDE.md"
