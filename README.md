# dotfiles

Personal config. Work-specific stuff lives outside this repo.

## Structure

```
.claude/CLAUDE.md    # Claude Code personal config (symlinked to ~/.claude/CLAUDE.md)
shell/zshrc          # Personal shell config (sourced by ~/.zshrc)
install.sh           # Sets up symlinks
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
- `push-dotfiles` commits and pushes this repo
- `pull-dotfiles` pulls and re-sources zshrc
- `sz` re-sources zshrc after edits

## Learning mechanism

Captures go to `~/.claude/INBOX.md` (local, never synced). On triage, entries get promoted to CLAUDE.md rules, zshrc aliases, scripts, or discarded. See `.claude/CLAUDE.md` Meta section for details.

Scripts live in a separate repo: [justin252/tools](https://github.com/justin252/tools/tree/main)
