Repo-level instructions for all agents working in this dotfiles repo.

## Setup

"Set up my dotfiles" → `bash ~/dotfiles/install.sh` then `source ~/.zshrc`. Done.

"Update dotfiles" → `pull-dot` (pulls, refreshes shared skills + Codex defaults, re-sources). Done.

"Repair dotfiles state" → `reset-dot` (repairs managed dotfiles state, then re-sources). Done.

Tell user after: create `~/.zshrc.work` / `~/.zshrc.personal` for machine-specific config (auto-sourced if present).

## Repo rules

- Keep README.md updated when structure changes
- `install.sh` must reflect new symlinks when paths change
- BSD (macOS) flag compatibility for all shell scripts
- Dotfiles shell/scripts must work on both macOS and Linux unless explicitly guarded
- Skills follow Agent Skills standard (`SKILL.md` with YAML frontmatter)
- Shared instructions live in `.agents/AGENTS.md`; tool-specific config in `.claude/` and `.cursor/`
- PRs: open as ready (not draft) – overrides global `--draft` default
- Git: use plain git (not Graphite) – `git checkout -b`, `git push`, `gh pr create`

## Testing

Before committing changes to shell scripts or tools, always run:
- `bash -n <file>` or `zsh -n <file>` on each modified script
- `zsh -c 'source ~/.zshrc && echo OK'` if shell config changed
- `zsh -c 'source ~/.zshrc; source ~/.zshrc'` if aliases/functions changed (catches conflicts)
- Live-test any new tool behavior (flags, env vars, subcommands)
- `HOME="$(mktemp -d)" bash install.sh` for install.sh changes

## Contribution rules

- `install.sh`: clean-machine-first; `mkdir -p` before `find`/loops; optional integrations should warn, not brick setup; only delete clearly managed paths
- `tools/`: require `-h`/`--help`, safe/idempotent defaults, and cross-platform shell behavior
- `skills/`: keep `SKILL.md` frontmatter valid and update workflow docs when the skill changes the model
- Workflow/docs: if commands or artifact flow change, update README.md and `.agents/AGENTS.md` in the same patch
