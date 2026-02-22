## Style

- Extremely concise. Sacrifice grammar for concision.
- Commit messages — single-line subject, no body. Let the diff speak.
- Plans, all interactions — concise. End plans with unresolved questions, if any.

## Code

- Clean, minimal code. Readability > cleverness.
- No over-engineering: no unnecessary abstractions, error handling, or features beyond what's asked.
- No adding comments/docstrings to untouched code.
- If a README exists and changes affect it, update it automatically.

## Safety

Even in yolo mode:
- Never `rm -rf` outside of build/temp dirs. Always scoped, never `~/` or `/`.
- Never `git push --force` to main/master.
- Never `git reset --hard` or `checkout .` with uncommitted work — stash first.
- Never delete branches without confirming they're merged.

## Git

- Conventional commits: feat:, fix:, chore:, refactor:, docs:, test:.
- Always run relevant tests before committing.
- GitHub CLI for all GitHub interactions.
- Always rebase, never merge — clean linear history.
- New repos → always `.gitignore` with `.DS_Store` immediately.

## Pull Requests

- Title: conventional commit format, under 70 chars
- Body structure:
  ```
  ## Summary
  - <what changed and why>

  ## Context
  <motivation, link to issue if applicable>

  ## Test plan
  - [ ] <how to verify>
  ```
- Reference issue numbers when applicable
- Per-repo CLAUDE.md can override this template

## Agent

- Prefer speed/autonomy when working from agreed plan
- Read-only ops (ls, web search, read queries) never need confirmation
- Log actions for visibility
- Exit loops if no progress toward verifiable goal
- Ask before guessing paths/values — don't assume from directory listings

## Modes

- `teach me [topic]` → Socratic method. Calibrate my level first, then make me reason.
- `debate me on [topic]` → Take opposing position seriously.
- `eli5 [topic]` → Simplest first, I'll ask deeper.

## Workflow

Branch naming: `<type>/<slug>` (e.g. `feat/add-grep-tool`). No direct pushes to main.

### Splitting changes
Prefer splitting logically independent changes (refactor, bug fix, feature) into stacked PRs.

**Proactive (preferred):** When I recognize a separable change while working, branch + commit it immediately before continuing. Cleanest path.

**Retroactive (at checkpoint):** If changes are already mixed, attempt to untangle (split commits, cherry-pick, rebase). If changes are too intertwined to split cleanly, ship as one PR and flag it — don't butcher the split.

Stack order: foundational changes (refactors, extractions, fixes) go first. Dependent features stack on top. Each PR targets the branch below it (or main for first).

### `checkpoint`
1. Build + test
2. Update README if changes affect it
3. Split into stacked PRs if possible (see above), or ship as one
4. Clean up commit history (squash/reword as needed)
5. Push branches, open PRs (global PR template)
6. Retro → INBOX.md

### `checkpoint yolo`
1. Build + test
2. Update README if changes affect it
3. Commit directly to main + push
4. Retro → INBOX.md

## Meta

How learning works: I read CLAUDE.md at session start — no persistent memory beyond this file. All captures go to `~/.claude/INBOX.md` (local, never synced). Only `triage` promotes to CLAUDE.md.

When to capture:
  Session ending?
  ├── Friction, loops, wrong assumptions?  → retro
  ├── Decisions or insights worth keeping? → retro
  ├── Just routine coding?                → checkpoint or close
  └── Sparked an idea?                    → log, then close
  Mid-session?
  ├── I hit friction and self-resolved     → I suggest INBOX.md entry (best-effort)
  └── You notice something reusable       → log

When I hit friction:
- Self-resolve once. If reusable insight, suggest INBOX.md entry.
- Never loop 3+ times on same failure — stop, note pattern, ask.

Commands — capture (quick, all write to ~/.claude/):
- `checkpoint` → see Workflow section above
- `checkpoint yolo` → see Workflow section above
- `retro` → review this session, learnings → INBOX.md
- `log` → idea/tangent → INBOX.md (date, context, idea, action)
- `save` → conversation → ~/.claude/sessions/<date>-<slug>.md
- `idea: <thought>` → ideate, then log to capture

Commands — curate (periodic):
- `triage` → review ~/.claude/INBOX.md: promote to CLAUDE.md (correct section), zshrc alias, ~/dotfiles/bin/ script, or discard. No sensitive content to CLAUDE.md.

## Setup

- `~/.claude/CLAUDE.md` → symlinked from `~/dotfiles/.claude/CLAUDE.md` — only edit the dotfiles copy
- `install.sh` creates symlinks; this is how the dotfiles repo works
- `~/.claude/INBOX.md` — local capture scratchpad, never synced
- `~/.claude/sessions/` — saved conversation logs, never synced
- Shell config layers: `dotfiles/shell/zshrc` (universal, synced) → `~/.zshrc.work` (work only) → `~/.zshrc.personal` (personal only). Machine-specific values go in local files.
- To detect context: check which local zshrc files exist on the machine.
- Scripts live in separate tools repo at `$TOOLS_PATH` (set per-machine in local zshrc). PRs required, no direct push to main.