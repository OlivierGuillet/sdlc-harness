#!/usr/bin/env bash
# Stop (blocking): do not let a turn end when architecture manifests have
# uncommitted changes and no ADR under docs/adr/ was added or modified.
. "$(dirname "$0")/lib.sh"

# Already continuing because of a Stop hook: let it stop, avoid loops.
[ "$(input_field '.stop_hook_active')" = "true" ] && exit 0

git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

changed="$(git -C "$ROOT" status --porcelain --untracked-files=all 2>/dev/null \
  | cut -c4- | sed -e 's/^.* -> //' -e 's/^"//' -e 's/"$//')"
[ -n "$changed" ] || exit 0

manifests=""
adr_touched=0
while IFS= read -r p; do
  [ -n "$p" ] || continue
  case "$p" in
    docs/adr/*.md) adr_touched=1; continue ;;
  esac
  case "$(basename "$p")" in
    Package.swift|project.xcproj|project.pbxproj|Podfile|Cartfile|build.gradle|build.gradle.kts|settings.gradle|settings.gradle.kts|libs.versions.toml|package.json)
      manifests="${manifests}${manifests:+, }${p}" ;;
  esac
done <<< "$changed"

if [ -n "$manifests" ] && [ "$adr_touched" -eq 0 ]; then
  jq -n --arg r "harness: architecture manifests changed (${manifests}) but no ADR was added or updated in docs/adr/. Use the adr skill to record the decision (docs/adr/NNNN-title.md) before finishing." \
    '{decision: "block", reason: $r}'
fi
exit 0
