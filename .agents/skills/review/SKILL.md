---
name: review
description: Review a PR or diff for correctness, style, and domain-specific issues. Use when the user says 'review', 'review this PR', or pastes a diff/PR URL.
---

# /review

Structured code review. Domain-aware via `~/.agents/references/`. For output-linked review loops, prefer `review-output`, which writes a durable `review.md` artifact.

## Bootstrap

1. Read `~/.agents/AGENTS.md` for conventions
2. Load relevant references from `~/.agents/references/` (e.g., `cli-guidelines.md` for CLI changes)
3. Determine target: PR URL, branch diff, or staged changes

## Input

- PR URL: `gh pr diff <url>` or `gh pr view <url> --json`
- Branch: `git diff origin/main...HEAD`
- Staged: `git diff --staged`

## Review Structure

For each file changed:

1. **Correctness**: bugs, edge cases, error handling gaps
2. **Style**: matches repo conventions (AGENTS.md rules, existing patterns)
3. **Domain**: applies loaded reference guidelines (CLI, security, testing)
4. **Completeness**: missing tests, README updates, migration steps

## Output

```
## <filename>

- [severity] finding. <explanation>
  suggestion: <concrete fix>
```

Severities: `blocker`, `issue`, `nit`, `question`.

## Principles

- Blockers first, nits last
- Concrete suggestions, not vague feedback
- Don't flag style issues covered by linters/formatters
- Acknowledge good patterns -- not everything needs a comment
- If the diff is large, focus on the riskiest changes
- If writing an output review artifact, route process/tooling lessons into `## Future learnings` rather than mixing them with code findings
