# sdlc-harness

Rules for working on this repository. The global rules in `dotfiles/CLAUDE.md` also apply.

## Harness & Installer Rules

- Never overwrite an existing file (e.g. `CLAUDE.md`, `settings.json`) without backing it up or merging into it first. Installers must be idempotent and non-destructive.
- Always pass non-interactive flags to external CLIs, e.g. `npx cc-sdd@latest --claude-skills --kiro-dir docs`, so users never hit interactive prompts.
- Run an independent review subagent on installer and hook changes before committing.
