# dotfiles

Universal config that works on any machine. Designed as a base layer; a separate work dotfiles repo can overlay on top via its own `install.sh` (which runs this one first, then adds work-specific symlinks). The overlay is optional – this repo works standalone.

## Quick start

> **Warning:** `install.sh` symlinks `~/.zshrc` – back up your existing shell config first.

```bash
git clone git@github.com:justin252/dotfiles.git ~/dotfiles
bash ~/dotfiles/install.sh
```

## Update (existing machine)

```bash
pull-dot
```

One command: pulls latest dotfiles and re-sources zshrc.

**Interactive learning path** – explore the repo with [Claude Code](https://docs.anthropic.com/en/docs/claude-code):

```bash
cd ~/dotfiles && claude
# then type: teach me how this works
```

Claude reads the repo's `.claude/CLAUDE.md` and `.agents/AGENTS.md` on startup, so the teaching mode works even before running `install.sh`. The repo is useful without Claude Code too – it's just shell config, tools, and agent instructions.

## What install.sh does

- Symlinks shell config (`~/.zshrc` → `shell/zshrc`), tools (`~/tools`), agent config (`~/.agents/`, `~/.claude/`, `~/.cursor/`)
- Symlinks `.claude/agents/` (CC subagent definitions)
- Seeds `~/.agents/INBOX.md`, `~/.agents/wins.md`, `~/documents/` (local-only, never synced)
- Copies Karabiner config (can't symlink – Karabiner overwrites symlinks)
- Sets `git pull.rebase true`
- Installs fzf, tmux if missing

`~/.zshrc` layering: `shell/zshrc` (universal, synced) sources `~/.zshrc.work` and `~/.zshrc.personal` if they exist. Work overlay is typically provided by a work dotfiles repo; personal overlay is local-only.

## Structure

```
.agents/AGENTS.md            # Shared agent instructions (cross-tool source of truth)
.agents/references/          # Reference docs auto-consulted by agents (e.g. CLI guidelines)
.agents/skills/              # Agent skills (symlinked to ~/.agents/, ~/.claude/; copied to ~/.cursor/)
.claude/CLAUDE.md            # Claude Code config (@imports AGENTS.md + Claude-specific)
.claude/agents/              # CC subagent definitions (implementer, researcher)
.claude/settings.json        # Claude Code permissions (dontAsk allow list)
shell/zshrc                  # Universal shell config (aliases, functions, env)
shell/tmux.conf              # tmux config (C-a prefix, vim nav, cross-platform clipboard)
tools/                       # CLI scripts on PATH (symlinked to ~/tools)
tools/ag                     # Agent session manager (tmux-backed: launch, list, attach, kill)
tools/doc                    # Unified doc browser: ~/documents/ + ~/.claude/plans/saved/ (colored tags, actions)
tools/convo                  # Session notes browser: ~/.claude/sessions/ (star, resume, search)
tools/refresh-skills         # Re-copy skills to ~/.cursor/skills/ (Cursor can't follow symlinks)
karabiner/karabiner.json     # Karabiner-Elements config (Joy-Con L → Claude Code controls)
karabiner/joycon-karabiner.md # Joy-Con mapping spec
install.sh                   # Sets up symlinks, seeds local files, installs fzf + tmux
AGENTS.md                    # Repo-level agent instructions (this repo)
```

## How it works

- `shell/zshrc` – universal config (this repo), works anywhere
- `tools/` – CLI scripts, symlinked to `~/tools` (on PATH)
- `~/.zshrc.work` – work-specific overlay (sourced if present; typically managed by a work dotfiles repo)
- `~/.zshrc.personal` – machine-specific personal overrides (local only)
- `~/.agents/AGENTS.md` – shared agent instructions, symlinked to this repo
- `~/.agents/skills/` – agent skills, symlinked to this repo; Claude Code discovers via symlink, Cursor via copied files (`refresh-skills` to sync)
- `~/.claude/CLAUDE.md` – Claude Code config, symlinked to this repo (@imports shared AGENTS.md)
- **Cursor global prefs** – paste AGENTS.md content into Cursor Settings > Rules > User Rules (no file-based auto-load for global prefs; per-project prefs use `AGENTS.md` at project root, auto-discovered natively)
- `~/.config/karabiner/karabiner.json` is copied from this repo (Karabiner breaks symlinks)
- `pull-dot` pulls and re-sources zshrc
- `sz` re-sources zshrc after edits
- `ag` – agent session manager: one command for parallel agent work. `ag <name>` auto-creates worktree + launches claude. `ag -m MSG` with initial task. `ag` fzf dashboard across all repos. `ag status` cross-repo unified view. `ag --cursor` for cursor + claude. `ag clean` sweeps dead sessions + merged worktrees.
- `wt` – git worktree plumbing (create/list/switch/delete). Mostly used through `ag`; direct use for worktree-only ops.
- `refresh-skills` – re-copy `~/.agents/skills/` to `~/.cursor/skills/` (run after editing skills, or via `pull-dot`)
- `doc` – unified doc browser: `~/documents/` [doc] + `~/.claude/plans/saved/` [plan] with colored tags, preview, actions (edit, view, implement, claude, cursor). `implement` action launches `ag` sessions from plans. `doc <query>` pre-filters.
- `convo` – session notes browser: `~/.claude/sessions/` [sesh] + `sessions/starred/` [★]. Star notable sessions, resume in Claude Code, or search old context. `convo <query>` pre-filters.

## Preference distribution

```
Personal global prefs (synced via this repo):
  ~/.agents/AGENTS.md        ← source of truth
  ├── Claude Code            @import via CLAUDE.md (native)
  ├── Cursor                 paste into User Rules (Settings UI, manual)
  └── Other tools            AGENTS.md at project root (native auto-discover)

Work overlay (synced via work dotfiles repo, if present):
  ~/.agents/AGENTS-work.md   ← work-specific rules
  ├── Claude Code            @import via CLAUDE.md (native)
  └── Cursor                 paste into User Rules (manual)
  ~/.agents/skills/          ← merged: personal + work skills
  └── Both tools discover via ~/.cursor/skills/ and ~/.claude/skills/

Project-specific patterns (committed to each repo):
  <repo>/AGENTS.md           ← team-shared, per-project
  └── All tools auto-discover natively
```

## Agent memory

Self-learning feedback loop across Claude Code and Cursor sessions.

```
session → friction/insights
    → /retro captures to INBOX.md (short-term, local)
    → /triage promotes to AGENTS.md (long-term, synced)
    → both tools read AGENTS.md at startup
    → better instructions → repeat
```

| Layer | File | Scope | Who writes |
|-------|------|-------|------------|
| Long-term | `.agents/AGENTS.md` | Cross-tool, synced | /triage only |
| Short-term | `~/.agents/INBOX.md` | Local, never synced | /retro, log, idea |
| Per-project | `<repo>/AGENTS.md` | Team-shared, committed | Manual or /triage |
| Per-project | `~/.claude/projects/*/memory/` | Claude Code auto-memory | Claude Code |

Capture triggers (both tools): `log`, `idea: <thought>`, `win: <description>`.
Triage (`/triage`) promotes INBOX items to AGENTS.md rules, zshrc aliases, scripts, or discards them.
