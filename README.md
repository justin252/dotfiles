# dotfiles

Universal config that works on any machine. Designed as a base layer; a separate work dotfiles repo can overlay on top via its own `install.sh` (which runs this one first, then adds work-specific symlinks). The overlay is optional – this repo works standalone.

## Quick start

> **Warning:** `install.sh` symlinks `~/.zshrc` – back up your existing shell config first.

```bash
git clone git@github.com:justin252/dotfiles.git ~/dotfiles
bash ~/dotfiles/install.sh
```

## Machine shapes

- Personal/universal machine: install `~/dotfiles`, then optionally create `~/.zshrc.personal` for machine-specific overrides.
- Work machine: install `~/dotfiles` first, then run `~/dotfiles-work/install.sh` to layer work-specific shell config, skills, and agent rules on top.

## Update (existing machine)

```bash
pull-dot
```

One command: pulls latest dotfiles, refreshes shared skills + Codex defaults, and re-sources zshrc.

## Repair (drifted machine state)

```bash
reset-dot
```

Repairs the dotfiles-managed layer without touching local-only state like auth, `~/.agents/docs`, `INBOX.md`, `~/.zshrc.work`, or `~/.zshrc.personal`.

**Interactive learning path** – explore the repo with [Claude Code](https://docs.anthropic.com/en/docs/claude-code):

```bash
cd ~/dotfiles && claude
# then type: teach me how this works
```

Claude reads the repo's `.claude/CLAUDE.md` and `.agents/AGENTS.md` on startup, so the teaching mode works even before running `install.sh`. The repo is useful without Claude Code too – it's just shell config, tools, and agent instructions.

## What install.sh does

- Symlinks shell config (`~/.zshrc` → `shell/zshrc`), tools (`~/tools`), agent config (`~/.agents/`, `~/.claude/`, `~/.cursor/`)
- Symlinks `.claude/agents/` (CC subagent definitions)
- Symlinks `~/.gemini/GEMINI.md` to `.gemini/GEMINI.md` (Gemini global context, @imports AGENTS.md)
- Syncs Codex defaults into `~/.codex/config.toml` without replacing auth/trust state
- Seeds `~/.agents/INBOX.md`, `~/.agents/wins.md`, `~/.agents/docs/` (local-only, never synced)
- Copies Karabiner config (can't symlink – Karabiner overwrites symlinks)
- Sets `git pull.rebase true`
- Installs fzf, tmux if missing

`~/.zshrc` layering: `shell/zshrc` (universal, synced) sources `~/.zshrc.work` and `~/.zshrc.personal` if they exist. Work overlay is typically provided by a work dotfiles repo; personal overlay is local-only.

## Structure

```
.agents/AGENTS.md            # Shared agent instructions (cross-tool source of truth)
.agents/.gitignore           # Boundary: docs/, INBOX.md, wins.md are local-only
.agents/references/          # Reference docs auto-consulted by agents
.agents/references/doc-templates.md  # Core docs + output/review artifact templates
.agents/skills/              # Agent skills (symlinked to ~/.agents/, ~/.claude/; copied to ~/.cursor/)
.codex/config.toml.example   # Codex CLI autonomy skeleton (merge, don't symlink blindly)
.codex/review-instructions.md # Review artifact template/instructions for Codex runner
.claude/CLAUDE.md            # Claude Code config (@imports AGENTS.md + Claude-specific)
.claude/agents/              # CC subagent definitions (executor, researcher)
.claude/settings.json        # Claude Code permissions (dontAsk allow list)
shell/zshrc                  # Universal shell config (aliases, functions, env)
shell/tmux.conf              # tmux config (C-a prefix, vim nav, agent status bar)
tools/                       # CLI scripts on PATH (symlinked to ~/tools)
tools/ag                     # Agent session manager (tmux-backed: launch, status, kill, clean)
tools/ag-status-line         # tmux status bar: agent state indicators (polled every 5s)
tools/doc                    # Unified doc browser: ~/.agents/docs/ (frontmatter-aware, typed actions)
tools/review-output          # Create/update output.md and run agent review ($AGENT_REVIEWER)
tools/sync-codex-config      # Set Codex CLI autonomy defaults (workspace-write + never ask)
tools/reset-dot              # Rebuild dotfiles-managed symlinks/copies/config scaffolding
tools/rebase-wip             # Stash current work, fetch/rebase, then restore work
tools/sesh                   # Session notes browser: ~/.agents/sessions/ (curated .md)
tools/refresh-skills         # Rebuild shared skills, sync Claude/Gemini/Cursor adapters
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
- `~/.agents/skills/` – shared runtime skill layer rebuilt by `refresh-skills` from base + optional work-overlay skills; Codex reads it directly, Claude symlinks to it, Cursor copies from it, Gemini uses generated slash commands in `~/.gemini/commands/`
- `~/.claude/CLAUDE.md` – Claude Code config, symlinked to this repo (@imports shared AGENTS.md)
- `~/.gemini/GEMINI.md` – Gemini global context, @imports shared AGENTS.md (same pattern as Claude's CLAUDE.md)
- `~/.codex/config.toml` – local Codex config. `install.sh` / `sync-codex-config` adds top-level autonomy defaults without replacing auth, trust, or profile-specific entries
- **Cursor global prefs** – paste AGENTS.md content into Cursor Settings > Rules > User Rules (no file-based auto-load for global prefs; per-project prefs use `AGENTS.md` at project root, auto-discovered natively)
- `~/.config/karabiner/karabiner.json` is copied from this repo (Karabiner breaks symlinks)
- `pull-dot` pulls, refreshes shared skills + Codex defaults, and re-sources zshrc
- `reset-dot` repairs dotfiles-managed state and re-sources zshrc
- `sz` re-sources zshrc + tmux.conf after edits
- `ag` – agent session manager: one command for parallel agent work. `ag <name>` auto-creates worktree + launches agent (defaults to Claude; use `--gemini` or `--codex` to switch). `ag <name> -m MSG` launches in background with guided output (doesn't attach). `ag` fzf dashboard across all repos. `ag status` cross-repo unified view (`--json` for scripts). `ag kill <name>` kill session. `ag --cursor` for cursor + agent. `ag clean` sweeps dead sessions + merged worktrees (`--force`/`--no-input` skips prompt). `AG_NO_INPUT=1` for scripting. Name = branch = status bar label everywhere.
- `wt` – git worktree plumbing (create/list/switch/delete). Mostly used through `ag`; direct use for worktree-only ops.
- `refresh-skills` – rebuild `~/.agents/skills` from dotfiles sources, then re-sync Claude symlinks, re-copy Cursor skills, and generate Gemini slash commands with real SKILL.md descriptions (run after editing skills, or via `pull-dot`)
- `sync-codex-config` – sync top-level Codex autonomy defaults without replacing auth, trust, or profile-specific settings
- `reset-dot` – rebuild the managed dotfiles layer after migrations or drift while preserving local-only state; leaves a real `~/tools` directory alone
- `review-output` – create/update `output.md` and run agent review into `review.md` for the current topic. Respects `$AGENT_REVIEWER` (codex only for now). Use `--background` for checkpoint-style async review
- `rebase-wip` – stash local edits, fetch/rebase onto the target branch, then reapply the stash. Useful when dotfiles change mid-task
- `doc` – unified doc browser: `~/.agents/docs/` with frontmatter-aware picker. Actions: edit, view, execute, propose, review, claude, gemini, plan, cursor. `doc <query>` pre-filters.
- `sesh` – session notes browser: `~/.agents/sessions/` (curated .md summaries for context handoff). `sesh <query>` pre-filters.

## Contributing

- `install.sh`: clean-machine-first; create dirs before scanning them; optional integrations should warn, not abort; only delete clearly managed paths
- `tools/`: keep `-h`/`--help`, idempotent defaults, and macOS/Linux shell compatibility
- `skills/`: keep YAML frontmatter valid and update workflow docs when behavior changes
- Smoke-test install/repair changes with a temp `HOME`, not just your live machine

## Preference distribution

```
Personal global prefs (synced via this repo):
  ~/.agents/AGENTS.md        ← source of truth
  ├── Claude Code            @import via CLAUDE.md (native)
  ├── Gemini CLI             @import via ~/.gemini/GEMINI.md (native)
  ├── Cursor                 paste into User Rules (Settings UI, manual)
  └── Other tools            AGENTS.md at project root (native auto-discover)

Work overlay (synced via work dotfiles repo, if present):
  ~/.agents/AGENTS-work.md   ← work-specific rules
  ├── Claude Code            @import via CLAUDE.md (native)
  └── Cursor                 paste into User Rules (manual)
  ~/.agents/skills/          ← merged: personal + work skills
  ├── Claude Code                symlinks from ~/.claude/skills/
  ├── Gemini CLI                 generated slash commands in ~/.gemini/commands/
  ├── Cursor                     copied to ~/.cursor/skills/
  └── Codex CLI                  reads ~/.agents/skills/ directly in this setup

Project-specific patterns (committed to each repo):
  <repo>/AGENTS.md           ← team-shared, per-project
  └── All tools auto-discover natively
```
## Agent memory

Self-learning feedback loop across Claude Code, Codex, and Cursor sessions.

```
session → friction/insights
    → /retro captures to INBOX.md (short-term, local)
    → /triage promotes to AGENTS.md (long-term, synced)
    → tools read AGENTS.md / shared skills / review artifacts
    → better instructions → repeat
```

| Layer | File | Scope | Who writes |
|-------|------|-------|------------|
| Long-term | `.agents/AGENTS.md` | Cross-tool, synced | /triage only |
| Short-term | `~/.agents/INBOX.md` | Local, never synced | /retro, log, idea |
| Per-project | `<repo>/AGENTS.md` | Team-shared, committed | Manual or /triage |
| Per-project | `~/.claude/projects/*/memory/` | Claude Code auto-memory | Claude Code |
| Per-topic | `~/.agents/docs/<topic>/review.md` | Output review + candidate learnings | Codex + executor loop |

Capture: `log`, `idea: <thought>`, `win: <description>`.
Triage (`/triage`) promotes INBOX items to AGENTS.md rules, problem.md docs, zshrc aliases, scripts, or discards them.
