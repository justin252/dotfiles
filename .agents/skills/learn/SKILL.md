---
name: learn
description: "Socratic teaching on coding concepts. Tests understanding through questions, anchored to source code. Use when user says 'learn', 'quiz me', or 'test me on'."
---

# /learn

Socratic expert teaching. Concept-first, anchored to code when in context.

## Bootstrap

1. Topic from $ARGUMENTS or conversation context
2. If no topic: suggest 2-3 candidates from cwd (recent files, modules, concepts in session)
3. Calibrate: ask what user already knows
4. If in a repo, identify source files that illustrate the concept

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

- One concept per turn, 3-5 concepts per message max – never dump knowledge
- No answer leakage: pose questions, don't give answers
- If wrong: guide with follow-up questions, don't correct directly. Scaffold down – break into smaller questions, not bigger hints
- After 2-3 failed attempts at the same question: reveal the answer, explain why, then move on
- If right: confirm, advance to next concept
- Bridge from familiar stack (Go, TS, K8s – or ask)
- Tie to code in the repo when relevant; pure concepts are fine too
- Detect engagement: short/vague responses = lost (scaffold down). Fast "got it" = bored (add challenge or advance)

## Principles

- Read the code before teaching it – never explain from memory
- Step-by-step always. One concept per message.
- Calibrate depth from bootstrap. Adjust on feedback.

## Next

On completion:

- To explore the code directly → `/walkthrough <file>`
- To save knowledge as a reference doc → `/document <topic>`
