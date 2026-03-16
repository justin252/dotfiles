@../.agents/AGENTS.md
@../.agents/AGENTS-work.md

## Agent

- Read-only ops (ls, web search, read queries) never need confirmation
- Avoid unnecessary bash: `echo`/`printf` for output (use direct text), interactive flags (`-i`), commands waiting on stdin – these hang on approval prompts.
- Hang detection applies to bash too: never sit idle waiting on a silent command.
- Plan files: auto-generated plans stay in `~/.claude/plans/` (Claude Code manages). For persistent plans, use /propose → artifacts/<topic>/plan.md.
- Skills override CLAUDE.md constraints for their active scope (e.g. /execute in autonomous mode overrides confirmation gates).
- If a build/run subagent is rejected, offer manual commands – don't retry the subagent.
- Permission denied in `ccy` mode: can't switch permission modes mid-session. Tell user the exact operation that was blocked, provide the manual command, and suggest running it in a new interactive `claude` session if multiple operations need approval.
- Autonomous session completion: print clear summary of what was done/remaining, then `tput bel` (terminal bell) to notify user the run finished.

## Working Posture

- **Plan** → Claude Code's built-in plan mode. Read-only, deliberate.
- **Execute** (default after plan approval) → Execute agreed plan. Handle errors autonomously (retry once, then flag). Pause at checkpoint: show diff, summarize, confirm before commit/push/PR.
- **POC** → `/poc <idea>`. Prove an idea works fast. See /poc skill.
- Autonomous mode (`/execute` with `ccy`) overrides behavioral confirmation gates. Hard safety rules still apply.

## Memory

See AGENTS.md § Memory for the model.

Claude Code additions:
- Auto-memory (`~/.claude/projects/*/memory/`): per-project, Claude manages. AGENTS.md wins on conflict.
- `load <query>` also searches `~/.agents/sessions/` (curated session summaries for context handoff).

## Setup

See AGENTS.md § Dotfiles for shell layering, install.sh, agent config distribution. See AGENTS-work.md § Dotfiles for the two-repo model and workspace lifecycle (loaded via @import above).

Claude Code specifics:
- `~/.claude/CLAUDE.md` → `~/dotfiles/.claude/CLAUDE.md` – only edit the dotfiles copy
- `~/.claude/settings.json` → `~/dotfiles/.claude/settings.json` – universal permissions. Work-specific MCP entries go in `~/.claude/settings.local.json` (not synced; arrays merge).
- Karabiner: `install.sh` copies (not symlinks) because Karabiner overwrites symlinks. After editing the dotfiles copy, run `cp ~/dotfiles/karabiner/karabiner.json ~/.config/karabiner/karabiner.json`.
- To detect context: check which local zshrc files exist on the machine (`~/.zshrc.work` = work context).

@RTK.md
