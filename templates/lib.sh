#!/usr/bin/env bash
# Shared helpers for the setup scripts in templates/. Source it:
#   . "$HERE/lib.sh"

# git_ignore <project-dir> <pattern>: add the pattern to the project's
# .gitignore unless it is already there. Used for the backups the scripts leave.
git_ignore() {
  local file="$1/.gitignore" pattern="$2"
  if [ -f "$file" ] && grep -qxF -- "$pattern" "$file"; then
    return 0
  fi
  # Start on a new line when the file does not end with one.
  if [ -s "$file" ] && [ -n "$(tail -c 1 "$file")" ]; then
    printf '\n' >> "$file"
  fi
  printf '%s\n' "$pattern" >> "$file"
  echo "ignored: $pattern (.gitignore)"
}
