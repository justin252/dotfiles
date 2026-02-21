# dotfiles

Personal config. Work-specific stuff lives outside this repo.

## Structure

```
.claude/CLAUDE.md    # Claude Code personal config (symlinked to ~/.claude/CLAUDE.md)
shell/zshrc          # Personal shell config (sourced by ~/.zshrc)
install.sh           # Sets up symlinks
INBOX.md             # Idea/friction capture (triaged during retro)
```

## Setup

```bash
git clone git@github.com:justin252/dotfiles.git ~/dotfiles
bash ~/dotfiles/install.sh
```

Then add to `~/.zshrc`:
```bash
source ~/dotfiles/shell/zshrc
[ -f ~/.zshrc.work ] && source ~/.zshrc.work
```

## How it works

- `~/.zshrc` is a 2-line loader — sources personal (this repo) and work (local only)
- `~/.claude/CLAUDE.md` is symlinked to this repo
- Work config (`~/.zshrc.work`, `AGENTS.local.md`) stays local, never committed here
- `sync-dotfiles` commits and pushes this repo
- `sz` re-sources zshrc after edits

## Learning mechanism

Claude captures friction/insights continuously into `CLAUDE.md` and `INBOX.md`. On retro, entries get triaged into: CLAUDE.md rules, zshrc aliases, scripts, or discarded. See `.claude/CLAUDE.md` Meta section for details.
