Fully autonomous. Auto-accept all INBOX.md reads/writes.

Review `~/.claude/INBOX.md` in two phases:

## Phase 1 – Sort

Single pass, all items in `## Inbox`:
- Add/verify `Triage:` metadata on each item (type, destination, effort)
- Before promoting: check if existing rules already cover the insight. Prefer strengthening existing rules over adding new lines
- Destination options:
  - `~/.claude/CLAUDE.md` – shared preferences (both Claude Code and Cursor benefit)
  - `~/.cursor/rules/*.mdc` – Cursor-only scoped rules
- Draft exact wording and verify fit against surrounding rules. Promote general principles, not one-off session friction. Deduplicate against other items being promoted in the same batch
- Quick items: execute inline (add a line, done) → move to `## Resolved`
- No longer relevant? Move to `## Resolved` with `discarded` + reason
- Medium/large: move to `## Refined` with priority + approach notes

Refined item format:
```
### <title>
- **Priority:** P1 (next) / P2 (soon) / P3 (someday)
- **Approach:** terse how-to-accomplish notes
- **Context:** distilled from original capture
```

## Phase 2 – Execute

- Pull from `## Refined` by priority (P1 first)
- Group by destination (e.g., CLAUDE.md changes, .mdc rules, bin/ scripts, zshrc)
- Execute each group as one change
- Resolved items move to `## Resolved` with disposition

## INBOX.md format

- Sections: `## Refined`, `## Inbox`, `## Resolved`
- Inbox items: `### YYYY-MM-DD HH:MM – <title>` with body + `**Triage:**` line
- Refined items: `### <title>` with Priority/Approach/Context fields
- Resolved items: single-line bullets – `YYYY-MM-DD HH:MM` – **title** – summary. **Disposition**
