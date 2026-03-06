@../.agents/AGENTS.md

## Agent

- Read-only ops (ls, web search, read queries) never need confirmation
- Avoid unnecessary bash: `echo`/`printf` for output (use direct text), interactive flags (`-i`), commands waiting on stdin – these hang on approval prompts.
- Hang detection applies to bash too: never sit idle waiting on a silent command.
- Plan files: auto-generated plans stay in `~/.claude/plans/` (Claude Code manages). Saved plans promoted to `~/.claude/plans/saved/<slug>.md` via `save plan`.
- Skills override CLAUDE.md constraints for their active scope (e.g. /yolo overrides "never commit without confirmation").
- If a build/run subagent is rejected, offer manual commands – don't retry the subagent.
- In Cursor sessions, read ~/.claude/CLAUDE.md early – Cursor doesn't auto-load it like Claude Code does.

## Working Posture

### Plan (`ccplan`)
Read-only research. Web, MCP, cross-repo, file reads.
- Probe for design decisions, edge cases, deep connections
- If task is simple, suggest switching to Execute
- Output: plan, design doc, proposal (use /design or /proposal-template when appropriate)
- No source code modifications

### Execute (default: `cc`)
**Quick** (default): brief motivation per diff. Approve-and-go. Pause at checkpoint.
**Teach** (say "teach"): narrative explanation of every change – how it fits the plan, gotchas, idioms. Link to code (`file:line`). Approve each logical unit.

Both: handle errors autonomously (retry once, then flag). Route commits through /checkpoint.

### Yolo (`ccy` → `/yolo <plan>`)
Full autonomy. Start `ccy`, then `/yolo <plan>` to kick off the loop.
- `/yolo` reads the plan, checks draft PRs for progress, loops: branch → implement → test → commit → draft PR
- For single tasks, plain `ccy` + describe what you want. No `/yolo` needed.
- Requires `ccy` – running `/yolo` from `cc` hits permission prompts.
- Hard safety rules still apply. Behavioral confirmation gates overridden.

## Memory

See AGENTS.md § Memory for the model.

Claude Code additions:
- Auto-memory (`~/.claude/projects/*/memory/`): per-project, Claude manages. AGENTS.md wins on conflict.
- `save plan [slug]` → `~/.claude/plans/saved/<slug>.md`. Header: `# Title` + `> Status: draft | active | done` + `> Repo: <repo> | Branch: <branch>`.
- `load plan <query>` → search `plans/saved/`, `plans/`, `docs/`. Partial match; ambiguous → show options.
- Docs: `~/.claude/docs/` for long-lived documents.

## Setup

- `~/.claude/CLAUDE.md` → symlinked from `~/dotfiles/.claude/CLAUDE.md` – only edit the dotfiles copy
- `~/.agents/AGENTS.md` → symlinked from `~/dotfiles/.agents/AGENTS.md` – shared cross-tool instructions
- `install.sh` creates symlinks; this is how the dotfiles repo works
- Karabiner: `install.sh` copies (not symlinks) `karabiner/karabiner.json` → `~/.config/karabiner/` because Karabiner overwrites symlinks. After editing the dotfiles copy, run `cp ~/dotfiles/karabiner/karabiner.json ~/.config/karabiner/karabiner.json` to sync live.
- `~/.agents/INBOX.md` – local capture scratchpad, never synced
- `~/.claude/plans/saved/` – saved plans (promoted from auto-generated `plans/`), never synced
- `~/.claude/docs/` – long-lived documents, never synced
- Shell config layers: `dotfiles/shell/zshrc` (universal, synced) → `~/.zshrc.work` (work only) → `~/.zshrc.personal` (personal only). Machine-specific values go in local files.
- To detect context: check which local zshrc files exist on the machine.
- Personal tools: `~/tools` (symlinked from `~/dotfiles/tools/`, on PATH).
- `~/code` – project root for all repos.
