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

- **Plan** → Claude Code's built-in plan mode. Read-only, deliberate.
- **Implement** (default after plan approval) → Execute agreed plan. Handle errors autonomously (retry once, then flag). Pause at checkpoint: show diff, summarize, confirm before commit/push/PR.
- **Yolo** → `/yolo <plan ref>`. Autonomous execution. See /yolo skill.
- **POC** → `/poc <idea>`. Prove an idea works fast. See /poc skill.
- Yolo/POC override behavioral confirmation gates. Hard safety rules still apply.

## Memory

See AGENTS.md § Memory for the model.

Claude Code additions:
- Auto-memory (`~/.claude/projects/*/memory/`): per-project, Claude manages. AGENTS.md wins on conflict.
- `save plan [slug]` → `~/.claude/plans/saved/<slug>.md`. Header: `# Title` + `> Status: draft | active | done` + `> Repo: <repo> | Branch: <branch>`.
- `load plan <query>` → search `plans/saved/`, `plans/`, `docs/`. Partial match; ambiguous → show options.
- Docs: `~/.claude/docs/` for long-lived documents.

## Setup

- `~/.claude/CLAUDE.md` → symlinked from `~/dotfiles/.claude/CLAUDE.md` – only edit the dotfiles copy
- `~/.claude/settings.json` → symlinked from `~/dotfiles/.claude/settings.json` – universal permissions. Work-specific MCP entries go in `~/.claude/settings.local.json` (not synced; arrays merge).
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
