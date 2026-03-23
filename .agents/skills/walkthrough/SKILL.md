---
name: walkthrough
description: "Opinionated code walkthrough. Dives into code step-by-step, explains gotchas, flags improvements. Use when user says 'walk me through', 'walk through', or 'tour'."
---

# /walkthrough

Opinionated code walkthrough. A senior engineer pairing with you – not just what the code does, but gotchas, improvements, and why it's built this way.

## Bootstrap

Determine what to walk through, in priority order:

1. **$ARGUMENTS** – file, dir, module, or topic provided explicitly
2. **Conversation context** – user pasted code, @file reference, or mentioned a specific area
3. **Auto-detect** – scan cwd: check git diff for recent changes, project structure, entry points. Suggest 2-3 candidates, let user pick.

If nothing to latch onto, ask: "What would you like to walk through?"

## Code Reference Format

Every code reference uses all three parts:

**`path/to/file.sh:42-51`** – brief label

```lang
<relevant snippet, trimmed>
```

<explanation>

- Bold file:line-range header + brief label
- Fenced snippet below (trimmed, not full file)
- Explanation follows
- Never snippet without location. Never location without snippet.

## Flow

Order: entry points first → primary data flow → branches/edge cases → gotchas.

- One concept per turn, 3-5 concepts per message max – never dump knowledge
- Start with the entry point (main, handler, test), not internal helpers
- Follow the primary data flow before exploring branches
- Present the code, explain what it does and why
- Flag gotchas, non-obvious behavior, potential bugs – roughly 1 per 100 lines, don't overwhelm
- Suggest improvements where warranted (but don't over-engineer)
- Light check-in: "make sense?" / "questions before we move on?"
- User asks to go deeper → go deeper. User says next → move on.
- If user shows conceptual confusion (asking "why" not "how") → suggest `/learn` for the underlying concept

## Principles

- Read the code before explaining – never from memory
- Opinionated: "here's what I'd change" is valuable, not just "here's what it does"
- Step-by-step always. One concept per message.
- Calibrate depth from bootstrap. Adjust on feedback.

## Next

On completion:

- To save what we covered as a reference doc → `/document <topic>`
- To test understanding of key concepts → `/learn <topic>`
