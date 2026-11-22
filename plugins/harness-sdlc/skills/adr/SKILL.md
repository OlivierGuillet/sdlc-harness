---
name: adr
description: Write and maintain Architecture Decision Records in docs/adr/. Use when a change adds, removes or upgrades a dependency, alters build or project configuration (Package.swift, project.xcproj or legacy project.pbxproj, Podfile, Gradle files, version catalogs, package.json), introduces a new module or layer, picks between technical alternatives, or when the harness require-adr hook blocks the end of a turn.
when_to_use: '"record a decision", "ADR", "why did we choose", "require-adr blocked", adding a library, changing architecture, superseding a previous decision.'
---

# Architecture Decision Records

ADRs live in `docs/adr/NNNN-kebab-case-title.md`, one decision per file, using
[template.md](template.md) (lightweight MADR).

## When an ADR is required

- A dependency is added, removed, or bumped across a major version.
- A build/project manifest changes in a way that alters architecture
  (targets, modules, minimum OS, toolchain, build plugins).
- A new layer, module, persistence mechanism, networking stack, or
  concurrency model is introduced.
- A design choice is made between real alternatives that a future reader would
  question.

In projects with a `.harness` marker, the `require-adr` Stop hook blocks the end
of a turn when a manifest (`Package.swift`, `project.xcproj` (Xcode 27+), `project.pbxproj` (legacy), `Podfile`, `Cartfile`,
`build.gradle*`, `settings.gradle*`, `gradle/libs.versions.toml`, `package.json`)
has uncommitted changes and no file under `docs/adr/` was added or modified.
A trivial patch bump still deserves a one-paragraph ADR, or an update of the ADR
that introduced the dependency (add a dated line under "More information").

## Procedure

1. `ls docs/adr` and take the next number (zero-padded to 4 digits, starting at `0001`).
2. Copy [template.md](template.md) to `docs/adr/NNNN-title.md`.
3. Fill in context, drivers, at least two considered options, the decision and
   its consequences (good and bad). Link the related spec:
   `docs/specs/<feature>/requirements.md` and requirement IDs (`REQ-<feature>-N.M`).
4. Status starts as `Proposed`; set `Accepted` once the user agrees.
5. Superseding: never edit an accepted decision's outcome. Write a new ADR, set
   the old one to `Superseded by NNNN`, and the new one `Supersedes NNNN`.

## Style

- Write for a reader six months from now who does not know the conversation.
- State facts and trade-offs; no marketing language.
- Keep it short: one screen is usually enough.
