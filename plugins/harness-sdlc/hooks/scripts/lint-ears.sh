#!/usr/bin/env bash
# PostToolUse (blocking feedback): after a spec file under docs/specs/ is
# written, every acceptance criterion must be a valid EARS sentence.
. "$(dirname "$0")/lib.sh"

rel="$(target_rel_path)"
case "$rel" in
  docs/specs/*.md) ;;
  *) exit 0 ;;
esac
file="$ROOT/$rel"
[ -f "$file" ] || exit 0

bad=""
while IFS=$'\t' read -r line text; do
  is_ears "$text" || bad="${bad}
  line ${line}: ${text}"
done < <(spec_criteria "$file")

[ -z "$bad" ] && exit 0

cat >&2 <<MSG
harness lint-ears: ${rel} has acceptance criteria that are not EARS sentences:${bad}
Each criterion must match one of (keywords in English, any case):
  The <system> shall <response>
  When <trigger>, the <system> shall <response>
  While <state>, the <system> shall <response>
  If <condition>, then the <system> shall <response>
  Where <feature>, the <system> shall <response>
Rewrite these lines now (see the ears-spec skill).
MSG
exit 2
