# Workflow Reference

Comprehensive reference for the full development setup. Not auto-loaded; access via `@~/.agents/references/workflow.md` or `load workflow`.

## Composability Stack

```
Layer 4: Skills       /implement, /checkpoint, /propose, /review, /retro
                      (skills call cleanup commands; /checkpoint offers wt clean after merge)
Layer 3: Agent        ag (tmux session manager – launch, list, attach, kill, -m prompt)
Layer 2: Code         wt (worktree dirs + status + clean), cc/ccy/ccplan (claude modes)
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

- **wt** – git worktree manager
  - `wt <name>` – create worktree from origin/default-branch
  - `wt` – list worktrees (fzf to switch)
  - `wt -d <name>` – delete worktree (auto-kills ag session)
  - `wt status` – unified view: worktree, branch, ag session, PR state
  - `wt clean` – remove worktrees with merged PRs + kill sessions
- **cc/ccy/ccplan** – claude mode aliases (see zshrc)

### Layer 3: Agent

- **ag** – tmux-backed agent session manager
  - `ag <name> [cmd]` – launch in worktree (default: claude)
  - `ag . [cmd]` – launch in current dir
  - `ag <name> [cmd] -m MSG` – launch + send initial prompt
  - `ag` – list sessions (fzf to attach)
  - `ag -k <name>` – kill session
  - `ag clean` – kill sessions with no running process
  - Session naming: `ag-<repo>-<name>` (dashes, shell-friendly)

### Layer 4: Skills

- `/implement` – execute phased plans
- `/checkpoint` – build, test, ship PRs, commit, push, retro
- `/propose` – draft RFC at ~/documents/
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
                            → seeds (INBOX.md, wins.md, ~/documents/)
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
~/documents/                    long-lived docs (RFCs, impl plans, research)
~/.agents/INBOX.md              short-term capture (local, never synced)
~/.agents/wins.md               promo-packet items
~/.claude/plans/saved/          promoted plans
~/.claude/sessions/             session notes
```

## Common Workflows

### Plan + parallel execute + ship

```bash
ccplan                          # plan (read-only research)
wss test-drive                  # SSH + tmux (skip if local)
wt SDA-1234                     # create worktree
ag SDA-1234 ccy -m "/implement from ~/documents/topic/impl.md phase 1"
wt SDA-5678                     # parallel worktree
ag SDA-5678 ccy -m "/implement from ~/documents/topic/impl.md phase 2"
wt status                       # monitor: worktrees + agents + PRs
ag                              # fzf to attach to agent
wt clean                        # after merge: remove worktrees + sessions
```

### Quick local fix

```bash
wt fix-typo                     # worktree locally
ag fix-typo ccy                 # agent in tmux
ag -k fix-typo && wt -d fix-typo  # cleanup
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
ag clean                  wt clean (auto-kills ag sessions for merged PRs)
wt -d <name>              /checkpoint (offers wt clean after PR merge)
wt clean                  gm (already prunes merged branches)
gclean                    tmux auto-destroys sessions when shell exits
```
