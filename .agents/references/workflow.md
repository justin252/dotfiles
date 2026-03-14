# Workflow Reference

Comprehensive reference for the full development setup. Not auto-loaded; access via `@~/.agents/references/workflow.md` or `load workflow`.

## Composability Stack

```
Layer 4: Skills       /implement, /checkpoint, /propose, /review, /retro
                      (skills call cleanup commands; /checkpoint offers wt clean after merge)
Layer 3: Agent        ag (orchestrator – auto-worktree, autonomous claude, dashboard, status)
Layer 2: Code         wt (worktree plumbing), cc/ccy/ccplan (claude modes)
Layer 1: Transport    wss (SSH+tmux), ws (workspaces CLI alias)
Layer 0: Infra        tmux.conf, install.sh, dotfiles sync
```

Each layer is independent. Skip any and the rest works:
- No workspace? Skip `wss`, use `wt`+`ag` locally
- No tmux? `wt` manages worktrees, `cc` runs claude
- No `ag`? `wt` + `cd` + `claude` manually

## Tools

### Layer 0: Infrastructure

- **tmux.conf** – C-a prefix, vim nav, minimal status bar. Symlinked via install.sh.
- **install.sh** – idempotent setup. Installs fzf, tmux, rtk. Symlinks shell, agent, claude configs. Seeds local files.

### Layer 1: Transport

- **ws** – alias for `workspaces` CLI (work-only, macOS guard)
- **wss** – SSH into workspace with persistent tmux session
  - `wss <name>` – SSH + tmux (attach or create "main" session)
  - `wss <name> -s` – plain shell (skip tmux)
  - `wss` – fzf picker from workspaces list
  - Cursor: `ws connect <name> -e cursor` directly

### Layer 2: Code

- **wt** – git worktree plumbing (mostly used through `ag`)
  - `wt <name>` – create worktree only (prefer `ag <name>`)
  - `wt` – list worktrees (fzf to switch)
  - `wt -d <name>` – delete worktree (auto-kills ag session)
  - `wt status` – unified view (also available as `ag status`)
  - `wt clean` – remove worktrees with merged PRs (also in `ag clean`)
- **cc/ccy/ccplan** – claude mode aliases for interactive work (see zshrc)

### Layer 3: Agent

- **ag** – agent session manager (stage 6-7 orchestrator)
  - `ag <name>` – auto-create worktree + launch claude
  - `ag <name> -m MSG` – launch with initial task
  - `ag <name> --cursor` – cursor + claude in worktree
  - `ag` – fzf dashboard (all sessions, all repos)
  - `ag status` – cross-repo unified view (sessions, branches, PR state)
  - `ag -k <name>` – kill session
  - `ag clean` – dead sessions + merged worktrees
  - Session naming: `ag-<repo>-<name>` (dashes, shell-friendly)
  - Mental model: `cc` = you drive (current dir). `ag` = parallel work (worktree, tmux-managed)

### Layer 4: Skills

- `/implement` – execute phased plans
- `/checkpoint` – build, test, ship PRs, commit, push, retro
- `/propose` – draft RFC at ~/.agents/docs/
- `/review` – review PR or diff
- `/retro` – capture friction to INBOX.md

## Dotfiles Model

Two repos:
- `~/dotfiles` (personal) – universal base layer, synced everywhere
- `~/dotfiles-work` (work) – overlay for work-specific config

### Shell config layering

```
~/.zshrc              -> ~/dotfiles/shell/zshrc         (universal)
  sources ~/.zshrc.work       (work overlay, if present)
  sources ~/.zshrc.personal   (personal overlay, if present)
```

### Config sync flow

```
dotfiles repo → install.sh → symlinks (zshrc, tmux.conf, agents, skills, claude)
                            → copies (karabiner, cursor skills)
                            → seeds (INBOX.md, wins.md, ~/.agents/docs/)
```

`pull-dot` – pull both repos, refresh cursor skills, re-source zshrc.

## Memory Model

```
session → INBOX.md (short-term) → triage → AGENTS.md (long-term)
```

- **AGENTS.md** – long-term memory, cross-tool, synced via dotfiles
- **INBOX.md** (`~/.agents/INBOX.md`) – short-term capture, local only
- **retro** – capture friction → INBOX.md
- **triage** – promote stable patterns → AGENTS.md or discard

Capture triggers:
- `log` / `idea: <thought>` → INBOX.md
- `win: <description>` → ~/.agents/wins.md

## Key File Paths

```
~/dotfiles/                     personal dotfiles repo
~/dotfiles-work/                work dotfiles repo
~/dotfiles/shell/zshrc          universal shell config
~/dotfiles/shell/tmux.conf      tmux config
~/dotfiles/tools/               tools on PATH (ag, h, doc, convo, etc.)
~/dotfiles/.agents/AGENTS.md    agent instructions (source of truth)
~/dotfiles/.agents/references/  reference docs (this file, cli-guidelines, etc.)
~/dotfiles/.agents/skills/      shared skill definitions
~/.agents/docs/                 long-lived docs (RFCs, impl plans, research)
~/.agents/INBOX.md              short-term capture (local, never synced)
~/.agents/wins.md               promo-packet items
~/.claude/plans/saved/          promoted plans
~/.claude/sessions/             session notes
```

## Common Workflows

### Implement from a plan

```bash
doc                                     # pick a plan → implement action → ag launches
# or manually:
ag auth-fix -m "/implement from ~/.agents/docs/auth/impl.md"
```

### Parallel tasks

```bash
ag task-a -m "fix the auth bug"         # auto-creates worktree, autonomous
ag task-b -m "add logging middleware"    # second agent, parallel
ag status                               # monitor all
ag                                      # fzf to attach to any agent
ag clean                                # after merge: cleanup
```

### Cursor + claude

```bash
ag feature-x --cursor                   # opens cursor + autonomous claude in worktree
```

### Quick local fix

```bash
ag fix-typo -m "fix typo in README"     # one command: worktree + agent + task
ag clean                                # cleanup after merge
```

### Reconnect after disconnect

```bash
wss test-drive                  # tmux reattaches, everything running
ag                              # agents still there
```

## Cleanup Flow

```
Manual commands           Triggered by skills/higher layers
─────────────────         ─────────────────────────────────
ag -k <name>              wt -d (auto-kills ag session)
ag clean                  /checkpoint (offers ag clean after PR merge)
wt -d <name>              gm (already prunes merged branches)
gclean                    tmux auto-destroys sessions when shell exits
```
