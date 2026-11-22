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
templates/                          per-project settings for iOS and Android
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
- never touches `~/.claude.json`.

The versioned `dotfiles/settings.json` stays machine-independent: the absolute path required by a `directory` marketplace source only exists in the generated file. Re-run `install.sh` after moving the clone or editing the template. Changes Claude Code writes to `~/.claude/settings.json` land in the generated file and are kept by the merge.

## The `.harness` marker

The plugin is installed globally, so its hooks run in every project. Each hook first checks for an empty `.harness` file at the project root (`$CLAUDE_PROJECT_DIR`). Without it, the hook exits immediately and does nothing. With it, these guardrails apply:

| Hook | Event | Effect |
|---|---|---|
| `session-start.sh` | SessionStart | Signal: injects the workflow and the list of specs and ADRs |
| `require-superpowers.sh` | PreToolUse (Write/Edit) | **Blocks** code edits while `superpowers@claude-plugins-official` is not enabled |
| `require-spec.sh` | PreToolUse (Write/Edit) | **Blocks** code edits (tests included) until `docs/specs/` holds a valid EARS criterion |
| `lint-ears.sh` | PostToolUse (Write/Edit) | **Rejects** a `docs/specs/**.md` file whose acceptance criteria are not EARS |
| `require-adr.sh` | Stop | **Blocks** the end of a turn when build manifests changed and no ADR was added or updated |

"Code" means source files (`.swift`, `.kt`, `.java`, `.ts`, `.py`, …) outside `docs/`, `.claude/` and `.kiro/`. Manifests such as `Package.swift` or `build.gradle.kts` are not blocked by `require-spec`; `require-adr` covers them instead.

Remove `.harness` to turn the guardrails off for a project. Skills stay available everywhere.

## Add the harness to a project

### iOS

```bash
~/sdlc-harness/templates/ios-setup.sh /path/to/project
```

It merges `templates/ios.settings.json` into `.claude/settings.json`, creates `.harness`, `docs/specs/` and `docs/adr/`, and exports Xcode's agent skills with `xcrun agent skills export --output-dir .claude/skills`. Add `--replace-skills` to refresh them after an Xcode update. It then offers to install cc-sdd.

### Android

```bash
cd /path/to/project
mkdir -p .claude docs/specs docs/adr
cp ~/sdlc-harness/templates/android.settings.json .claude/settings.json   # or merge by hand
touch .harness
npx cc-sdd@latest --kiro-dir docs
```

The template declares the `android-skills` (`android/skills`) and `android-cli-plugin` (`android/android-cli-plugin`) marketplaces and enables `android-skills@android-skills` and `android-cli@android-cli-plugin`. Claude Code offers to install them when you trust the folder; otherwise run `claude plugin install <plugin>@<marketplace> --scope project`.

### Any project

```bash
touch .harness
mkdir -p docs/adr
npx cc-sdd@latest --kiro-dir docs     # specs in docs/specs/, steering in docs/steering/
```

Commit `.harness`, `.claude/settings.json`, the cc-sdd skills and `docs/`.

## Daily workflow

1. `/kiro-steering` once per project, then for each feature `/kiro-spec-init`, `/kiro-spec-requirements` (EARS, IDs `REQ-<feature>-N.M`), design, tasks, `/kiro-validate-*`.
2. Architecture or dependency decision: an ADR in `docs/adr/` (`adr` skill).
3. superpowers: `writing-plans` from `tasks.md`, `test-driven-development` (one failing test per requirement ID), `subagent-driven-development`, `requesting-code-review`, `verification-before-completion`.
4. Do not use `/kiro-impl` or `/kiro-spec-batch`.

## Moving to a claude.ai marketplace later

The plugin lives in `plugins/harness-sdlc/`, not at the repo root, so the repository stays a plain multi-plugin marketplace that claude.ai can sync.

1. Push this repository to a private GitHub repo.
2. In `dotfiles/settings.json`, replace the `directory` source with
   `{ "source": "github", "repo": "<owner>/sdlc-harness" }`. The `${HARNESS_ROOT}` placeholder then disappears.
3. Either keep consuming it as a GitHub marketplace, or add it as a personal marketplace on claude.ai and register it locally with `claude plugin marketplace add --claudeai <name>`. It is then known as `claudeai-<name>`, so update the `enabledPlugins` key accordingly.
4. `claude plugin marketplace remove harness`, re-run `dotfiles/install.sh`, then `claude plugin install harness-sdlc@<new marketplace>`.

## Development

```bash
claude plugin validate .
claude plugin validate plugins/harness-sdlc
```

Bump `version` in `plugins/harness-sdlc/.claude-plugin/plugin.json`, then run `claude plugin marketplace update harness` and `claude plugin update harness-sdlc@harness`.
