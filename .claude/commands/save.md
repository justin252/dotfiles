---
description: Save current session to ~/.claude/sessions/
argument-hint: <slug>
disable-model-invocation: true
---

# /save $ARGUMENTS

Save current session to `~/.claude/sessions/` for later reference or transformation into documentation.

Slug: **$ARGUMENTS** (required — descriptive kebab-case, e.g., `auth-refactor`, `fix-memory-leak`)

## Behavior

1. Create `~/.claude/sessions/MM-DD-YY-<slug>.md` with:
   - **Header**: Date, slug, one-line summary
   - **Context**: What was the goal/problem
   - **Key decisions**: Important choices made and why
   - **Changes**: Files modified, PRs created
   - **Outcomes**: What was accomplished
   - **Follow-ups**: Open items, next steps

2. Format for future use:
   - Scannable headings
   - Links to PRs/commits where applicable
   - Code snippets only if essential for understanding

## Example output

```markdown
# 02-26-26 — auth-refactor

One-line: Refactored auth module to use JWT instead of sessions.

## Context
Needed stateless auth for horizontal scaling.

## Key decisions
- Chose JWT over sessions for statelessness
- 15min token expiry with refresh tokens

## Changes
- `src/auth/` — new JWT implementation
- PR #45: https://github.com/...

## Outcomes
- Auth now stateless, ready for k8s deployment

## Follow-ups
- [ ] Add rate limiting to refresh endpoint
```
