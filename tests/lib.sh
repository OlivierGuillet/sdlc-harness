#!/usr/bin/env bash
# Shared helpers for the harness test scripts. Source it first:
#   . "$(dirname "$0")/lib.sh"
# Every case gets a fresh project directory whose name contains a space.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
MARKER='<!-- harness-sdlc:project-claude-md -->'
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
FAILED=0

new_project() { # prints the path of a fresh "my project" directory
  local dir
  dir="$(mktemp -d "$TMP_ROOT/case.XXXXXX")/my project"
  mkdir -p "$dir"
  printf '%s' "$dir"
}

new_harness_project() { # same, opted in to the harness
  local dir
  dir="$(new_project)"
  touch "$dir/.harness"
  printf '%s' "$dir"
}

run_case() { # run_case <function name>; the case runs in a subshell
  local out
  if out="$("$1" 2>&1)"; then
    echo "ok   $1"
  else
    echo "FAIL $1"
    [ -n "$out" ] && printf '     %s\n' "$out"
    FAILED=1
  fi
}

fail() { echo "$*"; exit 1; } # aborts the current case

finish() { exit "$FAILED"; }
