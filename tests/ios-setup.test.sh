#!/usr/bin/env bash
# Tests for templates/ios-setup.sh (Xcode is stubbed out, cc-sdd is skipped).
. "$(dirname "$0")/lib.sh"

SETUP="$REPO/templates/ios-setup.sh"

installs_harness_claude_md() {
  local p; p="$(new_project)"
  local stub="$TMP_ROOT/stub-bin"
  mkdir -p "$stub"
  printf '#!/bin/sh\nexit 1\n' > "$stub/xcrun"
  chmod +x "$stub/xcrun"
  PATH="$stub:$PATH" "$SETUP" "$p" --no-cc-sdd </dev/null >/dev/null 2>&1 || fail "setup exited $?"
  [ -f "$p/CLAUDE.md" ] || fail "CLAUDE.md was not created"
  [ "$(head -n 1 "$p/CLAUDE.md")" = "$MARKER" ] || fail "first line is not the marker"
}

replaces_claude_md_written_by_cc_sdd() {
  local p; p="$(new_project)"
  local stub="$TMP_ROOT/stub-bin-npx"
  mkdir -p "$stub"
  printf '#!/bin/sh\nexit 1\n' > "$stub/xcrun"
  printf '#!/bin/sh\necho "# cc-sdd workflow" > CLAUDE.md\n' > "$stub/npx"
  chmod +x "$stub/xcrun" "$stub/npx"
  echo y | PATH="$stub:$PATH" "$SETUP" "$p" >/dev/null 2>&1 || fail "setup exited $?"
  [ "$(head -n 1 "$p/CLAUDE.md")" = "$MARKER" ] || fail "cc-sdd's CLAUDE.md was left in place"
  grep -qx "# cc-sdd workflow" "$p"/CLAUDE.md.bak-* || fail "cc-sdd's CLAUDE.md was not backed up"
}

installs_claude_md_even_when_cc_sdd_fails() {
  local p; p="$(new_project)"
  local stub="$TMP_ROOT/stub-bin-npx-fail"
  mkdir -p "$stub"
  printf '#!/bin/sh\nexit 1\n' > "$stub/xcrun"
  printf '#!/bin/sh\necho "# cc-sdd workflow" > CLAUDE.md\nexit 1\n' > "$stub/npx"
  chmod +x "$stub/xcrun" "$stub/npx"
  local status=0
  echo y | PATH="$stub:$PATH" "$SETUP" "$p" >/dev/null 2>&1 || status=$?
  [ "$status" != "0" ] || fail "setup hid the cc-sdd failure (exit 0)"
  [ "$(head -n 1 "$p/CLAUDE.md")" = "$MARKER" ] || fail "cc-sdd's CLAUDE.md was left in place"
}

git_ignores_the_settings_backup() {
  local p; p="$(new_project)"
  local stub="$TMP_ROOT/stub-bin"
  mkdir -p "$stub" "$p/.claude"
  printf '#!/bin/sh\nexit 1\n' > "$stub/xcrun"
  chmod +x "$stub/xcrun"
  echo '{}' > "$p/.claude/settings.json"
  PATH="$stub:$PATH" "$SETUP" "$p" --no-cc-sdd </dev/null >/dev/null 2>&1 || fail "setup exited $?"
  PATH="$stub:$PATH" "$SETUP" "$p" --no-cc-sdd </dev/null >/dev/null 2>&1 || fail "second setup exited $?"
  [ "$(grep -cxF '.claude/settings.json.bak-*' "$p/.gitignore")" = "1" ] || fail "expected the pattern exactly once in .gitignore"
}

run_case installs_harness_claude_md
run_case installs_claude_md_even_when_cc_sdd_fails
run_case git_ignores_the_settings_backup
run_case replaces_claude_md_written_by_cc_sdd
finish
