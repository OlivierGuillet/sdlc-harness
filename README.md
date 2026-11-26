# sdlc-harness

Personal SDLC harness for Claude Code, shipped as a plugin marketplace plus dotfiles.

- **Specs** with [cc-sdd](https://github.com/gotalab/cc-sdd): EARS requirements, design and tasks in `docs/specs/<feature>/`.
- **Execution** with [superpowers](https://github.com/obra/superpowers): brainstorming, plans, TDD, code review, verification.
- **Guardrails** with the `harness-sdlc` plugin: EARS and ADR skills, plus hooks that enforce them in opted-in projects.

```
.claude-plugin/marketplace.json     marketplace "harness" -> ./plugins/harness-sdlc
plugins/harness-sdlc/               the plugin (never at the repo root, see "claude.ai" below)
  .claude-plugin/plugin.json
  skills/ears-spec/                 EARS rules on top of cc-sdd, requirement ID -> test mapping
  skills/adr/                       Architecture Decision Records (docs/adr/NNNN-title.md)
  hooks/hooks.json, hooks/scripts/  guardrails, gated by the .harness marker
dotfiles/CLAUDE.md                  global rules (linked to ~/.claude/CLAUDE.md)
dotfiles/settings.json              global settings template (marketplace + enabled plugins)
dotfiles/install.sh                 links both files into ~/.claude
templates/                          per-project settings for iOS and Android, project CLAUDE.md
tests/                              bash tests for the setup scripts and hooks
```

## Install on a fresh machine

Requirements: Claude Code, `git`, `jq`, Node.js (for `npx`), Xcode 27 for iOS projects.

```bash
git clone <this repo> ~/sdlc-harness        # any location works
cd ~/sdlc-harness
dotfiles/install.sh --dry-run               # preview
dotfiles/install.sh
claude plugin marketplace add "$PWD"
claude plugin install harness-sdlc@harness
claude plugin install superpowers@claude-plugins-official
claude doctor
```

What `install.sh` does:

- backs up any existing `~/.claude/CLAUDE.md` and `~/.claude/settings.json` to `~/.claude/backups/harness-<timestamp>/`;
- links `~/.claude/CLAUDE.md` to `dotfiles/CLAUDE.md`;
- builds `dotfiles/settings.generated.json` (git-ignored) from `dotfiles/settings.json`. It replaces `${HARNESS_ROOT}` with the clone's path and deep-merges the result over your current settings, so personal keys survive. It then links `~/.claude/settings.json` to that file;
- enables this repository's versioned git hooks (`git config core.hooksPath .githooks`);
- never touches `~/.claude.json`.

The template also carries the status line (directory, git branch, model, context usage), so it follows you to every machine.

The versioned `dotfiles/settings.json` stays machine-independent: the absolute path required by a `directory` marketplace source only exists in the generated file. Re-run `install.sh` after moving the clone or editing the template. Changes Claude Code writes to `~/.claude/settings.json` land in the generated file and are kept by the merge.

## The `.harness` marker

The plugin is installed globally, so its hooks run in every project. Each hook first checks for an empty `.harness` file at the project root (`$CLAUDE_PROJECT_DIR`). Without it, the hook exits immediately and does nothing. With it, these guardrails apply:

| Hook | Event | Effect |
|---|---|---|
| `session-start.sh` | SessionStart | Signal: injects the workflow and the list of specs and ADRs; warns when cc-sdd skills or the harness `CLAUDE.md` are missing, or when discovery or design documents exist without any ADR |
| `require-superpowers.sh` | PreToolUse (Write/Edit) | **Blocks** code edits while `superpowers@claude-plugins-official` is not enabled |
| `require-spec.sh` | PreToolUse (Write/Edit) | **Blocks** code edits (tests included) until `docs/specs/` holds a valid EARS criterion |
| `lint-ears.sh` | PostToolUse (Write/Edit) | **Rejects** a `docs/specs/**.md` file whose acceptance criteria are not EARS |
| `require-adr.sh` | Stop | **Blocks** the end of a turn when build manifests changed and no ADR was added or updated |

"Code" means source files (`.swift`, `.kt`, `.java`, `.ts`, `.py`, …) outside `docs/`, `.claude/` and `.kiro/`. Manifests such as `Package.swift` or `build.gradle.kts` are not blocked by `require-spec`; `require-adr` covers them instead.

Remove `.harness` to turn the guardrails off for a project. Skills stay available everywhere.

## Add the harness to a project

Every recipe ends with `templates/install-claude-md.sh`. `npx cc-sdd` writes a `CLAUDE.md` that only describes cc-sdd and sends implementation to `/kiro-impl`. The script replaces it with `templates/project.CLAUDE.md`, which keeps the cc-sdd spec phases and hands implementation, debugging, review and verification to superpowers. An existing `CLAUDE.md` that differs from the template is moved to `CLAUDE.md.bak-<timestamp>` first, so nothing is lost, but the installed file is always the template: move anything you still need from the backup into `docs/steering/`, not back into `CLAUDE.md`. The script only runs in a directory that contains `.harness`, and it adds its backups to the project's `.gitignore`. Run the script again whenever cc-sdd is reinstalled or updated: the SessionStart hook warns when the file is no longer the harness one.

Always start Claude Code from the directory that contains `.harness`. Started from a parent directory, Claude Code finds neither `.claude/skills/` (so `/kiro-discovery` is an unknown command) nor the project settings, and the hooks stay silent.

### iOS

```bash
~/sdlc-harness/templates/ios-setup.sh /path/to/project
```

It merges `templates/ios.settings.json` into `.claude/settings.json`, creates `.harness`, `docs/specs/` and `docs/adr/`, and exports Xcode's agent skills with `xcrun agent skills export --output-dir .claude/skills`. Add `--replace-skills` to refresh them after an Xcode update. It then offers to install cc-sdd and installs the harness `CLAUDE.md`. If the cc-sdd install fails, the rest of the setup still runs and the script exits with an error that gives the command to retry.

### Android

```bash
cd /path/to/project
mkdir -p .claude docs/specs docs/adr
cp ~/sdlc-harness/templates/android.settings.json .claude/settings.json   # or merge by hand
touch .harness
npx cc-sdd@latest --claude-skills --kiro-dir docs
~/sdlc-harness/templates/install-claude-md.sh .
```

The template declares the `android-skills` (`android/skills`) and `android-cli-plugin` (`android/android-cli-plugin`) marketplaces and enables `android-skills@android-skills` and `android-cli@android-cli-plugin`. Claude Code offers to install them when you trust the folder; otherwise run `claude plugin install <plugin>@<marketplace> --scope project`.

### Any project

```bash
touch .harness
mkdir -p docs/adr
npx cc-sdd@latest --claude-skills --kiro-dir docs     # specs in docs/specs/, steering in docs/steering/
~/sdlc-harness/templates/install-claude-md.sh .       # harness CLAUDE.md, replaces the cc-sdd one
```

Commit `.harness`, `CLAUDE.md`, `.gitignore`, `.claude/settings.json`, the cc-sdd skills and `docs/`. Do not commit the `*.bak-*` backups.

## Daily workflow

The harness chains three phases after setup: specification with cc-sdd, architecture decisions, execution with superpowers. Each step leaves a deliverable in the repository.

### 1. Specification (cc-sdd)

| Step | Command | Deliverables |
|---|---|---|
| Steering (optional, once per project) | `/kiro-steering`, `/kiro-steering-custom` | `docs/steering/product.md`, `tech.md`, `structure.md`, plus any custom steering file |
| Discovery (each new piece of work) | `/kiro-discovery "idea"` | `docs/steering/roadmap.md` and one `docs/specs/<feature>/brief.md` per spec |
| Spec init | `/kiro-spec-init` | `docs/specs/<feature>/spec.json` and a `requirements.md` skeleton |
| Requirements | `/kiro-spec-requirements <feature>` | `requirements.md` with EARS acceptance criteria |
| Gap analysis (optional, existing code) | `/kiro-validate-gap <feature>` | `research.md` |
| Design | `/kiro-spec-design <feature>` | `design.md` and `research.md` |
| Design review (optional) | `/kiro-validate-design <feature>` | a verdict in the conversation, no file |
| Task breakdown | `/kiro-spec-tasks <feature>` | `tasks.md` |
| Progress (any time) | `/kiro-spec-status <feature>` | a status report, no file |

- You approve requirements, design and tasks one phase at a time.
- The `lint-ears` hook rejects a `requirements.md` whose acceptance criteria are not EARS.
- Requirement IDs are not written in `requirements.md`. They are derived from cc-sdd's numbering: `### Requirement 2`, criterion `3.` of the `login` spec is `REQ-login-2.3`. `tasks.md` refers to it as `_Requirements: 2.3_`, and tests carry the full ID in their name. Never renumber a requirement or a criterion once a test cites it.

### 2. Architecture decisions

| When | Tool | Deliverables |
|---|---|---|
| After `/kiro-discovery` and after each `/kiro-spec-design` | `harness-sdlc:adr` skill | `docs/adr/NNNN-title.md`, one per choice made between real alternatives, `Proposed` until you accept it |
| Whenever a build manifest changes | same skill, enforced by the `require-adr` hook | a new or updated ADR |

cc-sdd never writes ADRs. The first row is an instruction given by the project `CLAUDE.md` and the SessionStart hook, not a blocking hook; the SessionStart hook also warns when discovery or design documents exist and `docs/adr/` is empty.

### 3. Execution (superpowers)

| Step | Skill | Deliverables |
|---|---|---|
| Designing anything new | `brainstorming` | `docs/superpowers/specs/<date>-<topic>-design.md` |
| Implementation plan | `writing-plans`, fed by `tasks.md` | `docs/superpowers/plans/<date>-<feature>.md` |
| Implementation | `test-driven-development`, with `subagent-driven-development` or `executing-plans` | tests (at least one per requirement ID, written before the code), the code, the boxes ticked in `tasks.md` |
| Bug or failing test | `systematic-debugging` | the root cause, a test that reproduces it, the fix |
| Review | `requesting-code-review`, `receiving-code-review` | an independent reviewer's report and the fixes |
| Verification | `verification-before-completion` | the test and build output that proves the result |
| Wrap-up | `finishing-a-development-branch` | the merged branch or a pull request |

- Two hooks guard this phase: no code edit while superpowers is not enabled, and none until `docs/specs/` holds a valid EARS criterion.
- Do not use `/kiro-impl` or `/kiro-spec-batch`. cc-sdd installs them, but this phase replaces them.

## Moving to a claude.ai marketplace later

The plugin lives in `plugins/harness-sdlc/`, not at the repo root, so the repository stays a plain multi-plugin marketplace that claude.ai can sync.

1. Push this repository to a private GitHub repo.
2. In `dotfiles/settings.json`, replace the `directory` source with
   `{ "source": "github", "repo": "<owner>/sdlc-harness" }`. The `${HARNESS_ROOT}` placeholder then disappears.
3. Either keep consuming it as a GitHub marketplace, or add it as a personal marketplace on claude.ai and register it locally with `claude plugin marketplace add --claudeai <name>`. It is then known as `claudeai-<name>`, so update the `enabledPlugins` key accordingly.
4. `claude plugin marketplace remove harness`, re-run `dotfiles/install.sh`, then `claude plugin install harness-sdlc@<new marketplace>`.

## Development

### Validation

```bash
claude plugin validate .                     # marketplace: .claude-plugin/marketplace.json and each plugin entry
claude plugin validate plugins/harness-sdlc  # plugin: plugin.json, SKILL.md frontmatter, hooks/hooks.json
```

A skill whose YAML frontmatter does not parse still loads, but silently loses its name and description, so it never triggers. Only the validator catches this.

The `.githooks/pre-commit` hook runs both commands with `--strict`, where warnings count as errors, and refuses the commit if either fails. `install.sh` enables it; on a clone where you did not run `install.sh`, enable it with `git config core.hooksPath .githooks`. Bypass it once with `git commit --no-verify`.

The "plugin directory" findings (license, icon) only concern a submission to Anthropic's public plugin directory. They do not affect the result unless you add `--profile directory`.

### Tests

```bash
for t in tests/*.test.sh; do "$t" || echo "FAILED: $t"; done
```

Plain bash, no framework. Each case runs against a temporary project directory whose name contains a space.

### Shipping a change

- **Now (local `directory` marketplace).** Claude Code reads the plugin straight from this clone (`claude plugin list` shows `Read from: <clone>/plugins/harness-sdlc`). Edits to skills, hooks or scripts apply to the next session: no update command and no version bump needed. Changes to `dotfiles/settings.json` need `dotfiles/install.sh` again.
- **Later (GitHub or claude.ai marketplace).** Installed plugins are cached by version. Bump `version` in `plugins/harness-sdlc/.claude-plugin/plugin.json`, push, then run on each machine:

  ```bash
  claude plugin marketplace update <marketplace>
  claude plugin update harness-sdlc@<marketplace>
  ```
