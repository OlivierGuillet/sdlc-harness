#!/usr/bin/env bash
# SessionStart (signal only): inject the harness workflow and the current state
# of specs and ADRs as additional context.
. "$(dirname "$0")/lib.sh"

specs="none yet"
if [ -d "$ROOT/docs/specs" ]; then
  list=""
  for d in "$ROOT"/docs/specs/*/; do
    [ -d "$d" ] || continue
    f="$(basename "$d")"
    n=0
    [ -f "$d/requirements.md" ] && n="$(spec_criteria "$d/requirements.md" | wc -l | tr -d ' ')"
    list="${list}${list:+, }${f} (${n} criteria)"
  done
  [ -n "$list" ] && specs="$list"
fi

adrs="none yet"
if [ -d "$ROOT/docs/adr" ]; then
  count="$(find "$ROOT/docs/adr" -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-*.md' | wc -l | tr -d ' ')"
  last="$(find "$ROOT/docs/adr" -maxdepth 1 -name '[0-9][0-9][0-9][0-9]-*.md' -exec basename {} .md \; | sort | tail -3 | paste -sd ',' - | sed 's/,/, /g')"
  [ "$count" -gt 0 ] && adrs="${count} (latest: ${last})"
fi

warnings=""
[ -d "$ROOT/.claude/skills/kiro-spec-init" ] || warnings="${warnings}
- cc-sdd skills are not installed in this project: run \`npx cc-sdd@latest --kiro-dir docs\`."

ctx="This project uses the SDLC harness (.harness marker present). Guardrail hooks are active.
Workflow:
1. Specs with cc-sdd: /kiro-steering, /kiro-spec-init, /kiro-spec-requirements, design, tasks, /kiro-validate-*. Specs live in docs/specs/<feature>/. Do NOT use /kiro-impl or /kiro-spec-batch.
2. Acceptance criteria must be EARS (ears-spec skill); IDs are REQ-<feature>-<N>.<M>.
3. Architecture or dependency change: write an ADR in docs/adr/ (adr skill).
4. Execution with superpowers: brainstorming, writing-plans, test-driven-development (one failing test per REQ ID first), subagent-driven-development or executing-plans, requesting-code-review, verification-before-completion.
Blocking rules: no code edit without superpowers enabled and an EARS spec in docs/specs; malformed EARS criteria are rejected; a turn cannot end with manifest changes and no ADR.
Current specs: ${specs}
Current ADRs: ${adrs}${warnings:+
Warnings:${warnings}}"

jq -n --arg c "$ctx" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $c}}'
