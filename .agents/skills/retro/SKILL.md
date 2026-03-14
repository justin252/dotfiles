---
name: retro
description: Capture friction and learnings to ~/.agents/INBOX.md. Run at checkpoint, session end, and before context-loss events.
---

Review this session and capture learnings to `~/.agents/INBOX.md`.

## Scope (context-aware)

- **Full** (checkpoint, session end): scan all categories + ## Open audit. Skip empty ones.
- **Abbreviated** (before context loss – plan mode exit, repo switch, pause): friction + key decisions only. 30 seconds max.

Auto-trigger: don't wait to be asked. Run at checkpoint, session end, and before any context-loss event (mode switch, repo switch, long break).

## Categories

**Extractable patterns:**
- Ad-hoc scripts, pipelines, multi-step sequences worth keeping
- Repeated manual steps -> alias, function, or tool candidate
- Note: what it does, recurrence likelihood, destination (zshrc, tools/, skill)

**Friction:**
- Loops, wrong assumptions, blocked paths, wasted turns
- Permission prompts that interrupted autonomous flow
- Misunderstandings of intent or scope
- Tool limitations or missing capabilities

**Process:**
- What worked well, what didn't
- AGENTS.md rules that helped or were missing
- Over/under-prompting patterns

**## Open audit:**
- Scan `~/.agents/docs/*/` for active docs with ## Open sections
- Flag unresolved items that were addressed this session but not checked off
- Flag items that are now stale or no longer relevant

## Output

Write each finding as a separate entry under `## Inbox` in `~/.agents/INBOX.md`:

```markdown
### YYYY-MM-DD – <title>
<finding in 1-2 sentences>
**Triage:** <destination>. **Source:** claude-code|cursor|both
```

After writing, check INBOX.md size. If >10 items, nudge toward /triage.
