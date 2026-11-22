# Global rules (sdlc-harness)

These rules apply to every project. Project `CLAUDE.md` files may add to them.

## Language and naming

- Code, identifiers, file names, commit messages, specs, ADRs and documentation are written in English.
- Reply to me in the language I write in.

## Superpowers is mandatory

- At the start of every task, invoke the `superpowers:using-superpowers` skill and follow the skills it points to. Do not skip a skill because the task "looks simple".
- Execution always goes through superpowers:
  - `brainstorming` before designing anything new;
  - `writing-plans`, then `subagent-driven-development` or `executing-plans`;
  - `test-driven-development` for every behaviour change: red, green, refactor;
  - `systematic-debugging` for any bug or failing test;
  - `requesting-code-review` / `receiving-code-review` before merging;
  - `verification-before-completion` before claiming anything is done;
  - `finishing-a-development-branch` to wrap up.

## Specs: cc-sdd, execution: superpowers

| Phase | Tool |
|---|---|
| Steering, discovery | cc-sdd: `/kiro-steering`, `/kiro-discovery` |
| Requirements (EARS) | cc-sdd: `/kiro-spec-init`, `/kiro-spec-requirements`, plus the `harness-sdlc:ears-spec` skill |
| Design, task breakdown | cc-sdd: design and tasks skills, `/kiro-validate-*` |
| Architecture decisions | `harness-sdlc:adr` skill, in `docs/adr/` |
| Planning the implementation | superpowers `writing-plans`, fed by `docs/specs/<feature>/tasks.md` |
| Implementation, TDD, review, verification | superpowers |

- cc-sdd is installed per project with `npx cc-sdd@latest --kiro-dir docs`, so specs live in `docs/specs/<feature>/` and steering in `docs/steering/`.
- Never use `/kiro-impl` or `/kiro-spec-batch`: implementation belongs to superpowers.
- Each acceptance criterion has the ID `REQ-<feature>-<N>.<M>` (requirement N, criterion M). Every ID gets at least one test that carries it in its name, written before the code.

## Harness guardrails

- A project opts in with an empty `.harness` file at its root. Only then do the `harness-sdlc` hooks enforce the rules below; elsewhere they do nothing.
- In a `.harness` project:
  - code edits are refused until superpowers is enabled and `docs/specs/` contains an EARS requirement;
  - spec files with non-EARS acceptance criteria are rejected right after writing;
  - a turn cannot end with changed build manifests (`Package.swift`, `project.xcproj` (Xcode 27+), `project.pbxproj` (legacy), Gradle files, `package.json`, …) and no new or updated ADR.
- When a hook blocks, fix the cause (write the spec, the ADR, the EARS sentence). Never work around a hook or disable it without asking me.

## General

- Never commit or push unless I ask. Never write secrets, tokens or machine-specific absolute paths into versioned files.
- Ask before writing outside the current project directory.
