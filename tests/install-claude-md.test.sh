#!/usr/bin/env bash
# Tests for templates/install-claude-md.sh
. "$(dirname "$0")/lib.sh"

INSTALL="$REPO/templates/install-claude-md.sh"

backups() { find "$1" -maxdepth 1 -name 'CLAUDE.md.bak-*' | wc -l | tr -d ' '; }

creates_file_when_absent() {
  local p; p="$(new_harness_project)"
  "$INSTALL" "$p" >/dev/null || fail "installer exited $?"
  [ "$(head -n 1 "$p/CLAUDE.md")" = "$MARKER" ] || fail "first line is not the marker"
}

content_names_superpowers_and_forbids_kiro_impl() {
  local p; p="$(new_harness_project)"
  "$INSTALL" "$p" >/dev/null || fail "installer exited $?"
  local f="$p/CLAUDE.md" word
  for word in superpowers brainstorming test-driven-development /kiro-discovery tasks.md; do
    grep -qF -- "$word" "$f" || fail "missing: $word"
  done
  grep -Eq 'Never use .*/kiro-impl.*/kiro-spec-batch' "$f" || fail "does not forbid /kiro-impl and /kiro-spec-batch"
  ! grep -qF 'generate responses in English' "$f" || fail "still forces English replies"
}

backs_up_foreign_file() {
  local p; p="$(new_harness_project)"
  echo "mine" > "$p/CLAUDE.md"
  "$INSTALL" "$p" >/dev/null || fail "installer exited $?"
  [ "$(backups "$p")" = "1" ] || fail "expected 1 backup, got $(backups "$p")"
  grep -qx "mine" "$p"/CLAUDE.md.bak-* || fail "backup does not hold the original content"
  [ "$(head -n 1 "$p/CLAUDE.md")" = "$MARKER" ] || fail "new file has no marker"
}

no_backup_when_file_is_up_to_date() {
  local p; p="$(new_harness_project)"
  "$INSTALL" "$p" >/dev/null || fail "first run exited $?"
  "$INSTALL" "$p" >/dev/null || fail "second run exited $?"
  [ "$(backups "$p")" = "0" ] || fail "expected 0 backups, got $(backups "$p")"
}

backs_up_harness_file_edited_by_hand() {
  local p; p="$(new_harness_project)"
  "$INSTALL" "$p" >/dev/null || fail "first run exited $?"
  echo "my notes" >> "$p/CLAUDE.md"
  "$INSTALL" "$p" >/dev/null || fail "second run exited $?"
  [ "$(backups "$p")" = "1" ] || fail "expected 1 backup, got $(backups "$p")"
  grep -qx "my notes" "$p"/CLAUDE.md.bak-* || fail "backup does not hold the hand-written line"
  ! grep -qx "my notes" "$p/CLAUDE.md" || fail "file was not refreshed"
}

keeps_every_backup_within_the_same_second() {
  local p; p="$(new_harness_project)"
  echo "one" > "$p/CLAUDE.md"
  "$INSTALL" "$p" >/dev/null || fail "first run exited $?"
  echo "two" > "$p/CLAUDE.md"
  "$INSTALL" "$p" >/dev/null || fail "second run exited $?"
  [ "$(backups "$p")" = "2" ] || fail "expected 2 backups, got $(backups "$p")"
  cat "$p"/CLAUDE.md.bak-* | grep -qx "one" || fail "first backup was overwritten"
  cat "$p"/CLAUDE.md.bak-* | grep -qx "two" || fail "second backup is missing"
}

does_not_forbid_kiro_validate() {
  local p; p="$(new_harness_project)"
  "$INSTALL" "$p" >/dev/null || fail "installer exited $?"
  # The only /kiro-validate-* mentions allowed are in the workflow table.
  ! grep -v '^|' "$p/CLAUDE.md" | grep -qF 'kiro-validate' || fail "restricts a /kiro-validate-* command the global rules allow"
}

requires_an_adr_after_discovery_and_design() {
  local p; p="$(new_harness_project)"
  "$INSTALL" "$p" >/dev/null || fail "installer exited $?"
  grep -v '^|' "$p/CLAUDE.md" | grep -Eq 'After `/kiro-discovery` and after each `/kiro-spec-design`.*ADR' \
    || fail "no rule asking for ADRs after discovery and design"
}

fails_without_harness_marker() {
  local p; p="$(new_project)"
  echo "mine" > "$p/CLAUDE.md"
  local status=0
  "$INSTALL" "$p" >/dev/null 2>&1 || status=$?
  [ "$status" = "1" ] || fail "expected exit 1, got $status"
  [ "$(cat "$p/CLAUDE.md")" = "mine" ] || fail "CLAUDE.md was touched"
  [ "$(backups "$p")" = "0" ] || fail "a backup was created"
}

git_ignores_the_backup() {
  local p; p="$(new_harness_project)"
  printf 'build/\n' > "$p/.gitignore"
  echo "one" > "$p/CLAUDE.md"
  "$INSTALL" "$p" >/dev/null || fail "first run exited $?"
  echo "two" > "$p/CLAUDE.md"
  "$INSTALL" "$p" >/dev/null || fail "second run exited $?"
  grep -qx 'build/' "$p/.gitignore" || fail "existing .gitignore content was lost"
  [ "$(grep -cx 'CLAUDE.md.bak-\*' "$p/.gitignore")" = "1" ] || fail "expected the pattern exactly once in .gitignore"
}

leaves_gitignore_alone_without_backup() {
  local p; p="$(new_harness_project)"
  "$INSTALL" "$p" >/dev/null || fail "installer exited $?"
  [ ! -e "$p/.gitignore" ] || fail ".gitignore was created although nothing was backed up"
}

fails_on_missing_directory() {
  local p; p="$(new_project)/absent"
  local status=0
  "$INSTALL" "$p" >/dev/null 2>&1 || status=$?
  [ "$status" = "1" ] || fail "expected exit 1, got $status"
  [ ! -e "$p" ] || fail "directory was created"
}

run_case creates_file_when_absent
run_case content_names_superpowers_and_forbids_kiro_impl
run_case backs_up_foreign_file
run_case no_backup_when_file_is_up_to_date
run_case backs_up_harness_file_edited_by_hand
run_case keeps_every_backup_within_the_same_second
run_case does_not_forbid_kiro_validate
run_case requires_an_adr_after_discovery_and_design
run_case fails_without_harness_marker
run_case git_ignores_the_backup
run_case leaves_gitignore_alone_without_backup
run_case fails_on_missing_directory
finish
