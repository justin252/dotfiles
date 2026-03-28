---
name: lion
description: "🦁 Route intent to the right skill. Takes what you need done, reads the pipeline and existing state, suggests which skill to use and how. Use when unsure where to start, or say 'lion', 'route', 'what should I do'."
---

# /lion

Dispatch: read intent, check state, recommend the right skill and approach.

## Bootstrap

1. Read `~/.agents/docs/circus.md` § Animals for the pipeline
2. Parse intent from $ARGUMENTS or conversation context
3. Scan `~/.agents/artifacts/` for existing topic state

## Routing

Assess intent against two dimensions: **what exists** and **what they're asking for**.

### What exists already?

Check `~/.agents/artifacts/<topic>/` if a topic is identifiable:

| State | Recommendation |
|-------|---------------|
| Nothing | `/propose <topic>` – design first |
| problem.md or design.md, no plan | `/propose <topic>` – continue design |
| plan.md exists, phases unchecked | `/execute <topic>` – implement |
| Code changes, no PR | `/checkpoint` – ship it |
| output.md / PR exists, no review | `/review` – get feedback |
| review.md has blockers | `/execute` – fix review items |
| Messy git state, stacked PRs | `/tidy` – clean up first |
| INBOX.md growing (10+ items) | `/triage` – curate learnings |

### What are they asking for?

| Intent signal | Skill | Notes |
|--------------|-------|-------|
| "build X", "implement X" | Check for plan.md. Yes → `/execute`. No → `/propose` first. | |
| "design X", "think through X", "RFC" | `/propose` | |
| "ship this", "PR", "push" | `/checkpoint` | |
| "review PR #N", "look at this" | `/review` | |
| "clean up branches", "rebase" | `/tidy` | |
| "triage", "sort inbox" | `/triage` | |
| "document X", "write a reference" | `/document` | Not a pipeline skill |
| "quick proof of concept" | `/poc` | Compound: propose → execute → checkpoint |
| "create a ticket" | `/ticket` | Work-specific |
| "run the full pipeline" | `ag run <topic>` | Requires plan.md |

### Environment

| Situation | Recommendation |
|-----------|---------------|
| Simple, interactive task | Run inline (current session) |
| Multi-phase implementation | `ag <topic>` (worktree + session) |
| Large repo, heavy compute | `wss <workspace>` first |
| Multiple independent tasks | Separate `ag` sessions |

## Output

Present one recommendation with one alternative. Not a menu.

```
🦁 Recommendation: /execute feed-atlas
   Plan exists at ~/.agents/artifacts/feed-atlas/plan.md (4 phases, 0 done)
   Environment: ag feed-atlas (worktree, autonomous)
   Command: ag feed-atlas -m "/execute"

   Alternative: /propose feed-atlas – if the plan needs revision first
```

If no topic is identifiable, ask one clarifying question. Don't guess.

## Epilogue

Before completing, reflect:
- Was the routing obvious or did it require judgment?
- Did the user override the suggestion? What signal did I miss?
- Append 1-3 lines to `~/.agents/circus/lion.md`
