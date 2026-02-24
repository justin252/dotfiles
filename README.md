# dotfiles

Universal config that works on any machine. Machine-specific overlays (`~/.zshrc.work`, `~/.zshrc.personal`) stay local, never committed here.

## Structure

```
shell/zshrc              # Universal shell config (aliases, functions, env)
.claude/CLAUDE.md        # Claude Code config (symlinked to ~/.claude/CLAUDE.md)
.claude/commands/        # Custom slash commands (symlinked to ~/.claude/commands/)
karabiner/karabiner.json # Karabiner-Elements config (Joy-Con L → Claude Code controls)
karabiner/joycon-karabiner.md # Joy-Con mapping spec
templates/DESIGN.md      # Design doc template (used by /design command)
install.sh               # Sets up symlinks
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
[ -f ~/.zshrc.personal ] && source ~/.zshrc.personal
```

## How it works

- `shell/zshrc` — universal config (this repo), works anywhere
- `~/.zshrc.work` — work-specific (company tools, aliases, env vars) — local only
- `~/.zshrc.personal` — machine-specific personal overrides — local only
- `~/.zshrc` is a loader that sources all three in order
- `~/.claude/CLAUDE.md` is symlinked to this repo
- `~/.claude/commands/` is symlinked to this repo (custom slash commands like `/design`)
- `~/.config/karabiner/karabiner.json` is symlinked to this repo (Joy-Con L mappings for one-handed Claude Code in iTerm)
- `push-dot` commits and pushes this repo
- `pull-dot` pulls and re-sources zshrc
- `sz` re-sources zshrc after edits

## Learning mechanism

Captures go to `~/.claude/INBOX.md` (local, never synced). On triage, entries get promoted to CLAUDE.md rules, zshrc aliases, scripts, or discarded. See `.claude/CLAUDE.md` Meta section for details.

Scripts live in a separate repo: [justin252/tools](https://github.com/justin252/tools/tree/main)
