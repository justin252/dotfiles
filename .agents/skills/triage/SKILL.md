---
name: triage
description: "🐘 Three-scope triage: consolidate learnings, sort INBOX, promote to permanent homes. Reads per-animal learnings + workspace inboxes."
---

Fully autonomous. Auto-accept all reads/writes to INBOX.md, learnings, and SKILL.md files. Create PR for dotfiles changes – never merge without user confirmation.

**Batch limit:** Process max 10 items per invocation (across all phases) to prevent context bloat. If more remain, stop and note "run /triage again for remaining items."

## Phase 0 – Consolidate learnings

Read raw learnings and workspace inboxes, classify, inject into INBOX for processing.

1. Read all `~/.agents/circus/<animal>.md` files (if dir exists)
2. Read any `~/.agents/INBOX-ws-*.md` files (workspace-synced inboxes)
3. For each dated entry, classify into scope:
   - **[per-animal:<name>]**: specific to one animal's domain (e.g., "dog keeps hitting stale imports")
   - **[cross-animal:<source>→<target>]**: pattern spanning animals (e.g., "owl finds gaps dog misses")
   - **[project]**: affects planning/estimation (e.g., "auth work always takes 3x")
4. Inject classified items into `## Inbox` in INBOX.md with scope tags
5. Mark processed entries in learnings files with `## Last triage: YYYY-MM-DD` marker
6. Delete processed `INBOX-ws-*.md` files after merging

If `~/.agents/circus/` is empty or doesn't exist, skip Phase 0.

## Phase 1 – Sort

Single pass, all items in `## Inbox`:
- Add/verify `Triage:` metadata on each item (type, destination, effort)
- Before promoting: check if existing rules already cover the insight. Prefer strengthening existing rules over adding new lines. Draft exact wording and verify fit against surrounding rules. Promote general principles, not one-off session friction. Deduplicate against other items being promoted in the same batch.
- Destination options:
  - `~/.agents/AGENTS.md` – shared preferences (both Claude Code and Cursor benefit)
  - `~/.agents/AGENTS-work.md` – work-specific agent persona (no-op if missing)
  - `~/.agents/skills/<name>/SKILL.md` – per-animal findings (proven, 3+ occurrences)
  - `~/.agents/circus/<animal>.md` – cross-animal feedback (route to target animal)
  - `~/.cursor/rules/*.mdc` – Cursor-only scoped rules
  - `~/.agents/artifacts/<topic>/problem.md` – systemic issue worth a problem doc
- Quick items: execute inline (add a line, done) → move to `## Resolved`
- No longer relevant? Move to `## Resolved` with `discarded` + reason
- Medium/large: move to `## Refined` with priority + approach notes

### Promotion rules

1. Universal (any animal could hit this)? → AGENTS.md
2. Specific to one animal, proven (3+ occurrences)? → that animal's SKILL.md
3. Specific but unproven (1-2 occurrences)? → stays in learnings.md
4. Work-specific? → AGENTS-work.md (regardless of tier)

Refined item format:
```
### <title>
- **Priority:** P1 (next) / P2 (soon) / P3 (someday)
- **Approach:** terse how-to-accomplish notes
- **Context:** distilled from original capture
```

## Phase 2 – Execute
- Pull from `## Refined` by priority (P1 first)
- Group by destination (e.g., AGENTS.md changes, .mdc rules, bin/ scripts, zshrc)
- Execute each group as one change (PR or commit) – use judgement on granularity
- Resolved items move to `## Resolved` with disposition + PR link (or commit link if no PR)

## INBOX.md format
- Sections: `## Refined`, `## Inbox`, `## Resolved`
- Inbox items: `### YYYY-MM-DD HH:MM – <title>` with body + `**Triage:**` line
- Refined items: `### <title>` with Priority/Approach/Context fields
- Resolved items: single-line bullets – `YYYY-MM-DD HH:MM` – **title** – summary. **Disposition** [PR](url)
- No sensitive content to AGENTS.md

## Epilogue

Append 1-3 lines to `~/.agents/circus/elephant.md`: triage routing accuracy, items that should have been caught earlier, cross-animal patterns observed.

## Next

On completion, print: `Inbox triaged. Promoted N items to AGENTS.md`
