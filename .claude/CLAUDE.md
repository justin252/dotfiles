## Style

- Extremely concise. Sacrifice grammar for concision.
- Commit messages — single-line subject, no body. Let the diff speak.
- Plans, all interactions — concise. End plans with unresolved questions, if any.

## Code

- Clean, minimal code. Readability > cleverness.
- No over-engineering: no unnecessary abstractions, error handling, or features beyond what's asked.
- No adding comments/docstrings to untouched code.
- Primarily Go; open to best-fit language.

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

## Agent

- Prefer speed/autonomy when working from agreed plan
- Read-only ops (ls, web search, read queries) never need confirmation
- Log actions for visibility
- Exit loops if no progress toward verifiable goal

## Modes

- `teach me [topic]` → Socratic method. Calibrate my level first, then make me reason.
- `debate me on [topic]` → Take opposing position seriously.
- `eli5 [topic]` → Simplest first, I'll ask deeper.

## Checkpoint

When user says "checkpoint": build + test → update CLAUDE.md if needed → commit. If `~/dotfiles` has uncommitted changes, commit+push there too.

## Meta

Continuous learning — don't batch, capture as it happens:
- On friction (looping, wrong assumption, missing context): try to self-resolve once. If resolved, note the fix in CLAUDE.md for future sessions. If not, ask user, then note answer.
- Never loop 3+ times on same failure — stop, note pattern, ask.
- Proactive mid-session: if you notice something worth remembering, suggest a one-liner CLAUDE.md addition (don't interrupt flow).

Commands:
- `idea: <thought>` → discuss and refine the idea together.
- `log` → write current idea thread to `~/dotfiles/INBOX.md` as rich entry (date, context/repo+branch or "general", what was happening, the idea, suggested action).
- `save` → capture full conversation as markdown: what triggered it, key decisions + why, open questions, action items, what changed.
- `retro` → deeper review. Suggest CLAUDE.md updates + key takeaways. Triage `~/dotfiles/INBOX.md` entries into: CLAUDE.md rule, zshrc alias, `~/dotfiles/bin/` script, or discard.

Categories to capture (create sections as needed, date-stamp entries):
- **Research** — tools, techniques, patterns worth remembering
- **Learning** — mental models, insights, corrections to wrong assumptions
