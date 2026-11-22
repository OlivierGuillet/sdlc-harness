#!/usr/bin/env bash
# PreToolUse (blocking): refuse code edits until docs/specs holds at least one
# valid EARS acceptance criterion.
. "$(dirname "$0")/lib.sh"

rel="$(target_rel_path)"
[ -n "$rel" ] && is_code_file "$rel" || exit 0

while IFS= read -r f; do
  while IFS=$'\t' read -r _ text; do
    if is_ears "$text"; then exit 0; fi
  done < <(spec_criteria "$f")
done < <(spec_files)

deny_tool "harness: no EARS requirement found in docs/specs/. Write the spec first with cc-sdd (/kiro-spec-init then /kiro-spec-requirements, installed with 'npx cc-sdd@latest --kiro-dir docs'), following the ears-spec skill, before editing ${rel}. Tests count as code: TDD starts from the requirement IDs."
