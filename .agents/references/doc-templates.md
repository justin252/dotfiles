# Doc Templates

Agents consult these when creating docs in `~/.agents/docs/<topic>/`.

## Frontmatter schema

All doc types use this frontmatter:

```yaml
---
topic: <slug>           # matches directory name
repo: <repo-name>       # which repo this relates to (optional)
component: <area>       # subsystem/area (optional)
status: draft | active | done | abandoned
created: YYYY-MM-DD
updated: YYYY-MM-DD
chain: <position>       # e.g. "problem.md → **design.md**"
---
```

## Types

### problem.md – why

The trigger. What's broken, missing, or painful.

```markdown
---
topic: <slug>
status: draft
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
# Problem: <title>

## Impact
<what's broken and why it matters>

## Requirements
<what a solution must satisfy>

## Context
<how this surfaced, relevant history>

## Open
- [ ] <unresolved questions>
```

Scale to the problem. Quick tasks: 3-5 lines total, skip Context. Big initiatives: full template.

### design.md – how

The approach. Created by /propose after problem.md exists.

```markdown
---
topic: <slug>
status: draft
created: YYYY-MM-DD
updated: YYYY-MM-DD
chain: problem.md → **design.md**
---
# Design: <title>

## Approach
<how it works, key decisions>

## Tradeoffs
<what was considered, what was chosen and why>

## Requirements check
- [x] <requirement from problem.md> – how it's satisfied

## Open
- [ ] <unresolved questions>
```

### plan.md – what/when

Phased execution plan. Created by /propose (final step) or /execute.

```markdown
---
topic: <slug>
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
chain: problem.md → design.md → **plan.md**
---
# Plan: <title>

## Phase N: <Name>
- [ ] Task 1
- [ ] Task 2
- [ ] **Verify**: <test criteria>

## Open
- [ ] <unresolved questions>
```

/execute checks off tasks, adds references (PR links, file paths), and appends verification results.

### reference.md – learnings

Non-actionable knowledge. Created by /explain.

```markdown
---
topic: <slug>
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
# <title>

<content – explanations, patterns, how things work, code citations>
```

No pipeline, no ## Open. Just knowledge.

