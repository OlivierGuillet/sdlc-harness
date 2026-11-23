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

workflow_requires_adr_after_discovery_and_design() {
  local p; p="$(new_project)"
  touch "$p/.harness"
  context "$p" | grep -Eq 'after /kiro-discovery and after each /kiro-spec-design.*ADR' \
    || fail "workflow does not ask for ADRs after discovery and design"
}

ADR_WARNING='no ADR records'

warns_when_roadmap_exists_without_adr() {
  local p; p="$(new_project)"
  touch "$p/.harness"; mkdir -p "$p/docs/steering" "$p/docs/adr"
  echo "# Roadmap" > "$p/docs/steering/roadmap.md"
  context "$p" | grep -qF "$ADR_WARNING" || fail "no warning about missing ADRs"
}

warns_when_design_exists_without_adr() {
  local p; p="$(new_project)"
  touch "$p/.harness"; mkdir -p "$p/docs/specs/my feature"
  echo "# Design" > "$p/docs/specs/my feature/design.md"
  context "$p" | grep -qF "$ADR_WARNING" || fail "no warning about missing ADRs"
}

silent_about_adrs_when_one_exists() {
  local p; p="$(new_project)"
  touch "$p/.harness"; mkdir -p "$p/docs/steering" "$p/docs/adr"
  echo "# Roadmap" > "$p/docs/steering/roadmap.md"
  echo "# ADR" > "$p/docs/adr/0001-native-only.md"
  local ctx; ctx="$(context "$p")"
  [ -n "$ctx" ] || fail "hook produced no context"
  ! printf '%s' "$ctx" | grep -qF "$ADR_WARNING" || fail "unexpected warning"
}

silent_about_adrs_before_any_decision_document() {
  local p; p="$(new_project)"
  touch "$p/.harness"; mkdir -p "$p/docs/specs" "$p/docs/adr"
  local ctx; ctx="$(context "$p")"
  [ -n "$ctx" ] || fail "hook produced no context"
  ! printf '%s' "$ctx" | grep -qF "$ADR_WARNING" || fail "unexpected warning"
}

run_case workflow_names_discovery
run_case workflow_requires_adr_after_discovery_and_design
run_case warns_when_roadmap_exists_without_adr
run_case warns_when_design_exists_without_adr
run_case silent_about_adrs_when_one_exists
run_case silent_about_adrs_before_any_decision_document
run_case warns_when_claude_md_lacks_marker
run_case warns_when_claude_md_missing
run_case silent_about_claude_md_when_marker_present
run_case silent_without_harness_marker
finish
