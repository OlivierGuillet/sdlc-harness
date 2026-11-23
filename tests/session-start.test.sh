#!/usr/bin/env bash
# Tests for the CLAUDE.md warning of the SessionStart hook.
. "$(dirname "$0")/lib.sh"

HOOK="$REPO/plugins/harness-sdlc/hooks/scripts/session-start.sh"

context() { # context <project dir>: the additionalContext the hook injects
  echo '{}' | CLAUDE_PROJECT_DIR="$1" "$HOOK" | jq -r '.hookSpecificOutput.additionalContext'
}

warns_when_claude_md_lacks_marker() {
  local p; p="$(new_project)"
  touch "$p/.harness"; echo "# cc-sdd" > "$p/CLAUDE.md"
  context "$p" | grep -qF 'install-claude-md.sh' || fail "no warning about CLAUDE.md"
}

warns_when_claude_md_missing() {
  local p; p="$(new_project)"
  touch "$p/.harness"
  context "$p" | grep -qF 'install-claude-md.sh' || fail "no warning about CLAUDE.md"
}

silent_about_claude_md_when_marker_present() {
  local p; p="$(new_project)"
  touch "$p/.harness"; printf '%s\n# Project\n' "$MARKER" > "$p/CLAUDE.md"
  local ctx; ctx="$(context "$p")"
  [ -n "$ctx" ] || fail "hook produced no context"
  ! printf '%s' "$ctx" | grep -qF 'install-claude-md.sh' || fail "unexpected warning"
}

silent_without_harness_marker() {
  local p; p="$(new_project)"
  echo "# cc-sdd" > "$p/CLAUDE.md"
  local out; out="$(echo '{}' | CLAUDE_PROJECT_DIR="$p" "$HOOK")" || fail "hook exited $?"
  [ -z "$out" ] || fail "hook printed output outside a harness project"
}

workflow_names_discovery() {
  local p; p="$(new_project)"
  touch "$p/.harness"
  context "$p" | grep -qF '/kiro-discovery' || fail "workflow does not mention /kiro-discovery"
}

run_case workflow_names_discovery
run_case warns_when_claude_md_lacks_marker
run_case warns_when_claude_md_missing
run_case silent_about_claude_md_when_marker_present
run_case silent_without_harness_marker
finish
