---
name: propose
description: Draft an RFC at ~/.agents/docs/<topic>/rfc.md. Use when the user says 'propose', 'design', 'rfc', or needs to think through a system before building it.
---

# /propose

Research, then produce an RFC at `~/.agents/docs/<topic>/rfc.md`.

## Bootstrap

1. Read `~/.agents/AGENTS.md` for conventions
2. Determine topic from $ARGUMENTS or conversation context
3. Create `~/.agents/docs/<topic>/` if missing
4. If `rfc.md` exists, offer to resume or start fresh

## Workflow

1. Scan codebase for related systems, prior art, existing docs
2. Ask 2-3 focused questions to clarify scope
3. Draft iteratively -- present each section, refine
4. Write `rfc.md`; scaffold `impl.md` if phases are clear

## RFC Format

```markdown
---
status: draft
created: YYYY-MM-DD
topic: <slug>
---

# <Title>

<Blurb: what this is, why now, expected impact. 2-3 sentences.>

## Problem & Context
What exists today. What's broken or missing. How to measure impact.

## Proposal
Architecture, key decisions, trade-offs. Diagrams where useful.

## Implementation
Phased plan. Each phase: theme, tasks, validation. Feeds /implement.

## Open Questions
Numbered. Each with enough context to be actionable.
```

## Principles

- Most important information first. Blurb should stand alone.
- Concise. Cut anything a reader can infer. Defend against redundancy.
- Inline hyperlinks, never bracket citations.
- ASCII diagrams in fenced blocks (render everywhere).
- Implementation section converts directly to /implement phases.
- Open questions are blockers/decisions; roadmap lives in impl.md.
