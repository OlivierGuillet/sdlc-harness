# Harness-owned project CLAUDE.md

## Intent

`npx cc-sdd` writes a project `CLAUDE.md` that only describes cc-sdd. It
prescribes `/kiro-impl` and `/kiro-spec-batch`, presents `kiro-review`,
`kiro-debug` and `kiro-verify-completion` as the review, debug and verification
protocols, and forces English replies. All three contradict the harness, and a
teammate without the harness dotfiles sees only that version.

## Goals

- A harness project's `CLAUDE.md` states the harness workflow: cc-sdd for specs,
  superpowers for execution.
- The file is installed by the setup path, not by hand.
- A later cc-sdd run that rewrites the file is reported, not silently fixed.

## Non-goals

- Removing or patching cc-sdd skills in the project.
- Changing the global `dotfiles/CLAUDE.md`.

## Approaches

1. **Replace the file with a harness template (chosen).** One source of truth,
   no contradictory text left in the file.
2. Append a harness section to the cc-sdd file. Rejected: the conflicting
   instructions stay in the same file.
3. Delete `kiro-impl` / `kiro-spec-batch` from the project. Rejected: they come
   back on every cc-sdd update and `CLAUDE.md` stays wrong.

## Design

- `templates/project.CLAUDE.md`: the template. Its first line is the marker
  `<!-- harness-sdlc:project-claude-md -->`. It keeps cc-sdd's paths
  (`docs/steering/`, `docs/specs/`) and spec phases, hands implementation,
  debugging, review and verification to superpowers, forbids `/kiro-impl` and
  `/kiro-spec-batch`, and tells Claude to reply in the user's language while
  writing files in English.
- `templates/install-claude-md.sh [project-dir]`: copies the template to
  `<project>/CLAUDE.md`. An existing file that differs from the template is
  moved to `CLAUDE.md.bak-<timestamp>` first (changed after code review: the
  first version refreshed any file carrying the marker without a backup, which
  lost hand edits). An identical file is left alone. The script refuses to run
  without `.harness` and adds its backups to the project's `.gitignore`.
- `templates/ios-setup.sh` calls it as its last step, after the cc-sdd step,
  whatever the answer to the cc-sdd prompt.
- `session-start.sh` adds a warning when `CLAUDE.md` is missing or lacks the
  marker, naming the script to run.
- README: the Android and "Any project" recipes run the script after cc-sdd;
  a note says to start Claude from the directory that contains `.harness`.
- Tests: `tests/install-claude-md.test.sh` and `tests/session-start.test.sh`,
  plain bash, run against temporary directories.

## Left to the builder

Exact wording of the template and of the warning.
