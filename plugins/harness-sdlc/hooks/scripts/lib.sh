#!/usr/bin/env bash
# Shared helpers for harness-sdlc hooks. Source it first thing in every hook:
#   . "$(dirname "$0")/lib.sh"
# It reads the hook JSON from stdin into HOOK_INPUT, resolves the project root
# into ROOT, and EXITS 0 SILENTLY when the project has no .harness marker.

set -euo pipefail

HOOK_INPUT="$(cat || true)"

if ! command -v jq >/dev/null 2>&1; then
  # Without jq we cannot parse anything; never block because of a missing tool.
  exit 0
fi

ROOT="${CLAUDE_PROJECT_DIR:-}"
if [ -z "$ROOT" ]; then
  ROOT="$(printf '%s' "$HOOK_INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)"
fi

# The marker gate: no marker, no guardrails.
if [ -z "$ROOT" ] || [ ! -f "$ROOT/.harness" ]; then
  exit 0
fi

# --- helpers -----------------------------------------------------------------

input_field() { # input_field <jq filter>
  printf '%s' "$HOOK_INPUT" | jq -r "$1 // empty" 2>/dev/null || true
}

# Path of the file targeted by Write/Edit/MultiEdit/NotebookEdit, relative to ROOT.
target_rel_path() {
  local p
  p="$(input_field '.tool_input.file_path // .tool_input.notebook_path')"
  [ -n "$p" ] || return 0
  case "$p" in
    "$ROOT"/*) p="${p#"$ROOT"/}" ;;
    /*) ;; # outside the project: keep absolute
  esac
  printf '%s' "$p"
}

# True when the path is production or test code that requires a spec.
is_code_file() {
  local rel="$1" base
  base="$(basename "$rel")"
  case "$rel" in
    /*) return 1 ;;                                   # outside the project
    docs/*|.claude/*|.kiro/*|.github/*|.harness) return 1 ;;
  esac
  case "$base" in
    Package.swift|Podfile|Cartfile|build.gradle|build.gradle.kts|settings.gradle|settings.gradle.kts) return 1 ;;
  esac
  case "$base" in
    *.swift|*.m|*.mm|*.h|*.c|*.cc|*.cpp|*.hpp|*.kt|*.kts|*.java|*.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.py|*.rb|*.go|*.rs|*.dart|*.cs|*.php|*.scala|*.vue|*.svelte) return 0 ;;
  esac
  return 1
}

# Print "<line>\t<text>" for every EARS-checked line of a spec file:
# numbered items under "#### Acceptance Criteria" headings, and "[REQ-...]" lines.
spec_criteria() {
  awk '
    /^#{1,6}[[:space:]]/ { inac = ($0 ~ /^####[[:space:]]+Acceptance Criteria/) ; next }
    /\[REQ-[^]]*\]/ { t=$0; sub(/^.*\[REQ-[^]]*\][[:space:]]*/, "", t); printf "%d\t%s\n", NR, t; next }
    inac && /^[[:space:]]*[0-9]+\.[[:space:]]/ { t=$0; sub(/^[[:space:]]*[0-9]+\.[[:space:]]+/, "", t); printf "%d\t%s\n", NR, t }
  ' "$1"
}

# True when a sentence follows an EARS pattern (English keywords, any case).
is_ears() {
  local s
  s="$(printf '%s' "$1" | sed -E 's/^[*_`]+//; s/~~.*~~//')"
  printf '%s' "$s" | grep -Eiq '^(when|while|if|where|the)[[:space:],].*[[:space:]]shall([[:space:]]|$|[,.;:])'
}

spec_files() {
  [ -d "$ROOT/docs/specs" ] || return 0
  find "$ROOT/docs/specs" -type f -name '*.md' 2>/dev/null
}

deny_tool() { # deny_tool <reason>
  jq -n --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
  exit 0
}
