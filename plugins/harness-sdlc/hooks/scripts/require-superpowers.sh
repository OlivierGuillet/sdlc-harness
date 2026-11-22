#!/usr/bin/env bash
# PreToolUse (blocking): refuse code edits while superpowers is not enabled.
. "$(dirname "$0")/lib.sh"

rel="$(target_rel_path)"
[ -n "$rel" ] && is_code_file "$rel" || exit 0

key="superpowers@claude-plugins-official"
user_settings="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json"

# Highest precedence first: local project, shared project, user.
state=""
for f in "$ROOT/.claude/settings.local.json" "$ROOT/.claude/settings.json" "$user_settings"; do
  [ -f "$f" ] || continue
  v="$(jq -r --arg k "$key" '(.enabledPlugins // {}) | if has($k) then .[$k] | tostring else empty end' "$f" 2>/dev/null || true)"
  if [ -n "$v" ]; then state="$v"; break; fi
done

[ "$state" = "true" ] && exit 0

deny_tool "harness: superpowers must be enabled before editing code in this project (${key} is ${state:-not enabled}). Run: claude plugin install ${key}  (or set enabledPlugins[\"${key}\"]=true), then start the work with the superpowers skills (brainstorming, writing-plans, test-driven-development)."
