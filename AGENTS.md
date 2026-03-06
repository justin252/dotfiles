Repo-level instructions for all agents working in this dotfiles repo.

## Setup

"Set up my dotfiles" → `bash ~/dotfiles/install.sh` then `source ~/.zshrc`. Done.

Tell user after: create `~/.zshrc.work` / `~/.zshrc.personal` for machine-specific config (auto-sourced if present).

## Repo rules

- Keep README.md updated when structure changes
- `install.sh` must reflect new symlinks when paths change
- BSD (macOS) flag compatibility for all shell scripts
- Skills follow Agent Skills standard (`SKILL.md` with YAML frontmatter)
- Shared instructions live in `.agents/AGENTS.md`; tool-specific config in `.claude/` and `.cursor/`
- PRs: open as ready (not draft) – overrides global `--draft` default
- Git: use plain git (not Graphite) – `git checkout -b`, `git push`, `gh pr create`
