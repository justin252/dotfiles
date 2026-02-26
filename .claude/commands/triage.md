---
description: Process ~/.claude/INBOX.md — sort, prioritize, execute
disable-model-invocation: true
---

# /triage

Process `~/.claude/INBOX.md` — sort, prioritize, execute.

## Usage
```
/triage
```

## Behavior

Fully autonomous. Auto-accept INBOX.md reads/writes. Auto-checkpoint dotfiles changes and auto-merge PR.

### Phase 1 — Sort

Single pass through `## Inbox`:

1. **Add/verify Triage metadata** on each item:
   - Type: insight (config/rule), task (build something), friction (process issue)
   - Destination: CLAUDE.md `<section>`, zshrc, `~/tools` script, backlog, unsure
   - Effort: quick, medium, large
   - Example: `**Triage:** insight → CLAUDE.md Agent, quick`

2. **Before promoting**: check if existing rules already cover it. Prefer strengthening existing rules over adding new lines. Deduplicate against other items in same batch.

3. **Quick items**: execute inline (add a line, done) → move to `## Resolved`

4. **No longer relevant**: move to `## Resolved` with `discarded` + reason

5. **Medium/large**: move to `## Refined` with priority + approach notes

### Refined item format

```markdown
### <title>
- **Priority:** P1 (next) / P2 (soon) / P3 (someday)
- **Approach:** terse how-to-accomplish notes
- **Context:** distilled from original capture
```

### Phase 2 — Execute

1. Pull from `## Refined` by priority (P1 first)
2. Group by destination (CLAUDE.md, zshrc, scripts)
3. Execute each group as one change (PR or commit)
4. Move resolved items to `## Resolved` with disposition + PR link

### INBOX.md format

```markdown
## Refined
### <title>
- **Priority:** P1/P2/P3
- **Approach:** ...
- **Context:** ...

## Inbox
### YYYY-MM-DD HH:MM — <title>
Body text...
**Triage:** type → destination, effort

## Resolved
- `YYYY-MM-DD HH:MM` — **title** — summary. **Disposition** [PR](url)
```

## Guidelines

- Promote general principles, not one-off session friction
- No sensitive content to CLAUDE.md
- Trigger when INBOX.md exceeds ~10 items
