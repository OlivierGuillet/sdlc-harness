# Harness-owned project CLAUDE.md Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A harness project's `CLAUDE.md` describes the harness workflow (cc-sdd for specs, superpowers for execution) instead of the cc-sdd-only file that `npx cc-sdd` writes.

**Architecture:** A versioned template carrying a marker comment, a small install script that copies it into a project (backing up a foreign file), a call from `ios-setup.sh`, and a SessionStart warning when the marker is absent.

**Tech Stack:** bash, jq (already required), plain bash test scripts.

**Spec:** `docs/superpowers/specs/2026-11-23-project-claude-md-design.md`

## Global Constraints

- Marker, verbatim, first line of the template: `<!-- harness-sdlc:project-claude-md -->`
- Everything written in English; no machine-specific absolute paths in versioned files.
- No commits: the owner commits themselves.
- Scripts use `set -euo pipefail` and quote every path (project paths contain spaces).

## Review Focus

- Project path with spaces (`Save My Ink`): install and warning still work. Test in Task 1.
- Re-running the installer: no backup pile-up when the file already has the marker. Test in Task 1.
- Existing hand-written `CLAUDE.md`: never lost, backed up. Test in Task 1.
- Project directory that does not exist: non-zero exit, nothing created. Test in Task 1.
- Project without `.harness`: the hook stays silent whatever `CLAUDE.md` contains. Test in Task 2.

---

### Task 1: Template and installer

**Files:**
- Create: `templates/project.CLAUDE.md`
- Create: `templates/install-claude-md.sh` (executable)
- Test: `tests/install-claude-md.test.sh` (executable)

**Interfaces:**
- Produces: `templates/install-claude-md.sh [project-dir]` (default `.`), exit 0 on success, exit 1 when the directory does not exist. Marker string as in Global Constraints.

- [ ] **Step 1: Write the failing test.** Each case runs in a fresh `mktemp -d` subdirectory named `my project` (with a space):
  - `creates_file_when_absent`: after the run, `CLAUDE.md` exists and its first line is the marker.
  - `content_names_superpowers_and_forbids_kiro_impl`: file contains `superpowers`, `test-driven-development`, `/kiro-discovery`, and a line matching `Never use .*/kiro-impl.*/kiro-spec-batch`; it does not contain `generate responses in English`.
  - `backs_up_foreign_file`: a pre-existing `CLAUDE.md` containing `mine` yields exactly one `CLAUDE.md.bak-*` containing `mine`, and the new file has the marker.
  - `no_backup_when_marker_present`: running twice leaves zero `CLAUDE.md.bak-*`.
  - `fails_on_missing_directory`: exit code non-zero, directory not created.
  The script prints `ok`/`FAIL` per case and exits non-zero on any failure.
- [ ] **Step 2: Run** `tests/install-claude-md.test.sh`. Expected: FAIL (installer missing).
- [ ] **Step 3: Write `templates/project.CLAUDE.md`.** Sections: Paths (steering `docs/steering/`, specs `docs/specs/`, ADRs `docs/adr/`); Language (reply in the user's language, files in English); Workflow table (discovery/steering and spec phases with cc-sdd commands, ADR skill, then superpowers `writing-plans`, `test-driven-development`, `systematic-debugging`, `requesting-code-review`, `verification-before-completion`, `finishing-a-development-branch`); Rules (never `/kiro-impl` or `/kiro-spec-batch`; `kiro-review`, `kiro-debug`, `kiro-verify-completion` are not used, superpowers equivalents are; requirement IDs `REQ-<feature>-<N>.<M>`, one test per ID written first; human approval between requirements, design and tasks); Steering (load `product.md`, `tech.md`, `structure.md`); a closing note on how to refresh the file.
- [ ] **Step 4: Write `templates/install-claude-md.sh`.** Resolve the template next to the script; back up to `CLAUDE.md.bak-$(date +%Y%m%d-%H%M%S)` only when the target exists and `grep -qF` does not find the marker; copy; print one `created:`/`replaced:`/`refreshed:` line.
- [ ] **Step 5: Run** `tests/install-claude-md.test.sh`. Expected: all `ok`, exit 0.

### Task 2: SessionStart warning

**Files:**
- Modify: `plugins/harness-sdlc/hooks/scripts/session-start.sh` (warnings block)
- Test: `tests/session-start.test.sh` (executable)

**Interfaces:**
- Consumes: the marker string.

- [ ] **Step 1: Write the failing test.** Run the hook with `CLAUDE_PROJECT_DIR=<tmp>/my project` and `echo '{}'` on stdin, read `.hookSpecificOutput.additionalContext` with jq:
  - `warns_when_claude_md_lacks_marker`: `.harness` present, `CLAUDE.md` is `# cc-sdd` → context contains `install-claude-md.sh`.
  - `warns_when_claude_md_missing`: `.harness` present, no `CLAUDE.md` → same.
  - `silent_about_claude_md_when_marker_present`: marker file → context does not contain `install-claude-md.sh`.
  - `silent_without_harness_marker`: no `.harness` → empty stdout, exit 0.
- [ ] **Step 2: Run** `tests/session-start.test.sh`. Expected: the two `warns_*` cases FAIL.
- [ ] **Step 3: Add the warning** next to the existing cc-sdd one: `- CLAUDE.md is missing or was not written by the harness (cc-sdd may have rewritten it): run templates/install-claude-md.sh from the sdlc-harness clone on this project.`
- [ ] **Step 4: Run** both test scripts. Expected: all `ok`.

### Task 3: Wire into setup, document, apply

**Files:**
- Modify: `templates/ios-setup.sh` (header comment, new step 5, final echo)
- Modify: `README.md` (iOS paragraph, Android and Any-project recipes, commit list, "start Claude from the directory containing `.harness`" note, layout listing if it enumerates templates)
- Test: `tests/ios-setup.test.sh` (executable)

**Interfaces:**
- Consumes: `templates/install-claude-md.sh <project-dir>`.

- [ ] **Step 1: Write the failing test.** `installs_harness_claude_md`: with a stub `xcrun` that exits 1 first in `PATH`, run `templates/ios-setup.sh "<tmp>/my project" --no-cc-sdd </dev/null`; assert exit 0 and that `CLAUDE.md`'s first line is the marker.
- [ ] **Step 2: Run** `tests/ios-setup.test.sh`. Expected: FAIL (no `CLAUDE.md`).
- [ ] **Step 3: Call the installer** as the last step of `ios-setup.sh`, after the cc-sdd block and outside its `if`.
- [ ] **Step 4: Run** all three test scripts. Expected: all `ok`.
- [ ] **Step 5: Update `README.md`.**
- [ ] **Step 6: Run** `templates/install-claude-md.sh` on the Save My Ink project and check the marker and the backup of the cc-sdd file.
- [ ] **Step 7: Run** `claude plugin validate . --strict` and `claude plugin validate plugins/harness-sdlc --strict`. Expected: both pass.
