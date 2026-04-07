# Dotfiles Conventions

Auto-consult when modifying dotfiles, install.sh, tools, or shell config.

## Shell config layering

```
~/.zshrc              -> ~/dotfiles/shell/zshrc         (universal, synced)
  sources ~/.zshrc.work       (work overlay, if present)
  sources ~/.zshrc.personal   (personal overlay, if present)
```

Overlays are symlinked by their respective install scripts. Personal zshrc ends with `true` to avoid exit-code leaks from conditional last lines.

## install.sh

Idempotent. Safe to re-run anytime. What it does:
- Symlinks: `~/.zshrc`, `~/tools`, `~/.agents/AGENTS.md`, `~/.agents/skills/*/`, `~/.agents/conventions/`, `~/.agents/docs/`, `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.claude/agents/`
- Copies skills to `~/.cursor/skills/` (Cursor doesn't follow symlinks)
- Seeds local-only dirs: `~/.agents/artifacts/`, `~/.agents/sessions/`, `~/.agents/state/`, `~/.agents/circus/`, `~/.notes/`; files: `~/.agents/INBOX.md`, `~/.agents/wins.md`
- Installs fzf if missing (brew on macOS, binary download on Linux)
- Sets `git pull.rebase true`
- Karabiner: copies (not symlinks) on macOS

### Contribution defaults

- Clean-machine-first: `mkdir -p` before `find`/loops over managed dirs
- Optional integrations warn instead of aborting the full install
- Only delete clearly managed paths; if a path might contain user content, prefer symlink-only removal or warn
- Validate on both macOS/BSD and Linux/GNU shell behavior

## Agent config distribution

```
~/.agents/AGENTS.md          <- source of truth
  Claude Code                @import via CLAUDE.md (native)
  Cursor                     paste into User Rules (Settings > Rules)

~/.agents/AGENTS-work.md     <- work overlay (if present)
  Claude Code                @import via CLAUDE.md (native)
  Cursor                     paste into User Rules alongside AGENTS.md

~/.agents/skills/            <- merged personal + work skills
  Claude Code                symlinks from ~/.claude/skills/
  Cursor                     copied to ~/.cursor/skills/
  Codex CLI                  reads ~/.agents/skills/ directly in this setup

Repo-root AGENTS.md          <- per-project, auto-discovered by both tools
```

Cursor does NOT follow @import or read `~/.agents/` directly. User Rules (plain text in Settings UI) is the only global mechanism; no file-based auto-load. Paste both AGENTS.md and AGENTS-work.md into User Rules for full context.

Cursor skills: copied (not symlinked) because Cursor doesn't follow symlinks for skill discovery (known bug). Run `dot` to rebuild skills (it refreshes automatically). `dot` rebuilds `~/.agents/skills` from dotfiles sources, then re-syncs Claude/Cursor from that shared layer.

## Key tools

All on PATH via `~/tools` symlink:
- `h` -- fzf alias browser. `h suggest` surfaces forgotten aliases from history.
- `dotfiles` -- unified dotfiles sync: pull repos, verify/repair symlinks, refresh skills, sync configs, re-source shell. `dotfiles setup` for full rebuild. `dotfiles doctor` for read-only diagnostics.
- `sz` -- re-source zshrc after edits
- `rebase-wip` -- stash local edits, fetch/rebase onto a target branch, then reapply the stash. Useful when dotfiles change mid-task
- `ag` -- agent session manager. `ag <name>` auto-creates worktree + launches agent. `ag <name> -m MSG` background launch. `ag` fzf dashboard. `ag status` cross-repo view. `ag kill/clean` lifecycle.
- `wt` -- navigate to any branch or PR. `wt <branch>` finds/creates worktree. `wt 90` or `wt <PR-URL>` resolves PR. `wt` fzf switch. `wt -d` delete. `wt clean` merged worktrees.
- `artifacts` (`a`) -- unified artifact browser (fzf). Frontmatter-aware picker. Actions: edit, view, execute, propose, review, ide, claude, codex.
- `review` -- Codex code review for any PR or branch. Always async; writes `review.md` to auto-discovered topic dir.
- `sessions` (`s`) -- session notes browser (fzf). Curated .md summaries for context handoff.
- `notes` (`n`) -- personal topic notes browser (fzf). Learning notes from `/learn` sessions.
- `t` -- tools browser (fzf). Discovers all tools in `~/tools/`, grouped by `# category:` comment.

## Testing dotfiles changes

```bash
# Sandbox test (isolated HOME, stubs, behavioral)
bash ~/dotfiles/tests/sandbox.sh

# Quick checks (no sandbox needed)
zsh -n <file>                               # syntax check
zsh -c 'source ~/.zshrc; source ~/.zshrc'   # double-source
```
