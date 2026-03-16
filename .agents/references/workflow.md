# Workflow Reference

Comprehensive reference for the full development setup. Not auto-loaded; access via `@~/.agents/references/workflow.md` or `load workflow`.

## Composability Stack

```
Layer 4: Skills       /execute, /checkpoint, /propose, /review, /retro
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
- **rebase-wip** – stash current work, fetch/rebase, then restore work. Useful for mid-session branch updates without manually juggling a stash
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

- `/execute` – execute phased plans
- `/checkpoint` – build, test, ship PRs, commit, push, trigger async review, retro
- `/propose` – create/continue problem → design → plan pipeline in ~/.agents/artifacts/
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
                            → seeds (INBOX.md, wins.md, ~/.agents/artifacts/)
```

`pull-dot` – pull both repos, refresh shared skills, sync Codex defaults, re-source zshrc.

## Memory Model

```
session → INBOX.md (short-term) → triage → AGENTS.md (long-term)
```

- **AGENTS.md** – long-term memory, cross-tool, synced via dotfiles
- **INBOX.md** (`~/.agents/INBOX.md`) – short-term capture, local only
- **retro** – capture friction → INBOX.md
- **triage** – promote stable patterns → AGENTS.md or discard

Capture:
- `log` / `idea: <thought>` → INBOX.md
- `win: <description>` → ~/.agents/wins.md

## Artifact Lifecycle

Core docs plus delivery artifacts:

```
problem.md → design.md → plan.md → output.md → review.md → checkpoint/ship
reference.md (learnings, not actionable)
```

Most topics use one `output.md` and one `review.md`. Multi-output topics can add `outputs/<slug>.md` and `reviews/<slug>.md` when a plan truly spans multiple reviewable deliverables.

Each lives in `~/.agents/artifacts/<topic>/` with YAML frontmatter (topic, repo, component, status).
Templates: `~/.agents/references/artifact-templates.md`.

### Composability

Three layers feed each other:
- **Plan mode** = thinking (ephemeral, conversation-scoped)
- **artifacts/<topic>/** = writing it down (persisted artifacts)
- **/execute** = executing (tracked progress in plan.md, output.md, review.md)

| From | To | What happens |
|---|---|---|
| Plan mode | /propose | Captures conversation context into problem/design |
| Plan mode | /execute | Creates minimal plan.md, starts executing |
| /propose | /execute | Design done → plan.md → execute |
| /execute | /checkpoint | Ships the current output and can trigger async review |
| /execute | /propose | Pauses, updates design with learnings |
| Any | /retro | Scans ## Open and review learnings, captures friction |

### Skill → artifact mapping

- /propose → problem.md, design.md, plan.md (context-aware, picks up where left off)
- /execute → resumes plan.md and keeps output links current
- /checkpoint → ships the current output and may launch review.md generation
- /review → reviews a diff/PR; Codex-backed output review writes review.md
- /explain → reference.md
- /retro → scans ## Open sections and Future learnings
- /triage → can promote INBOX items to problem.md

## Key File Paths

```
~/dotfiles/                     personal dotfiles repo
~/dotfiles-work/                work dotfiles repo
~/dotfiles/shell/zshrc          universal shell config
~/dotfiles/shell/tmux.conf      tmux config
~/dotfiles/tools/               tools on PATH (ag, h, artifacts, sesh, etc.)
~/dotfiles/.agents/AGENTS.md    agent instructions (source of truth)
~/dotfiles/.agents/references/  reference docs (this file, cli-guidelines, etc.)
~/dotfiles/.agents/skills/      shared skill definitions
~/.agents/artifacts/<topic>/    long-lived artifacts: problem, design, plan, output, review, reference
~/.agents/INBOX.md              short-term capture (local, never synced)
~/.agents/wins.md               promo-packet items
~/.agents/sessions/             curated session summaries
```

## Common Workflows

### Execute from a plan

```bash
artifacts                               # pick a plan → execute action → ag launches
# or manually:
ag auth-fix -m "/execute from ~/.agents/artifacts/auth/plan.md"
```

### Review the current output

```bash
review-output ~/.agents/artifacts/auth
# or from artifacts:
artifacts                               # pick output/review → review action
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
