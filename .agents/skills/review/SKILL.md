---
name: review
description: "🦉 Review a PR or diff for correctness, style, and domain-specific issues. Use when the user says 'review', 'review this PR', or pastes a diff/PR URL."
---

# /review

Structured code review. Domain-aware via `~/.agents/conventions/`. Always persists `review.md` to the topic's artifact dir.

## Bootstrap

1. Read `~/.agents/AGENTS.md` for conventions
2. Load relevant conventions from `~/.agents/conventions/` (e.g., `cli-guidelines.md` for CLI, `shell-scripts.md` for shell scripts)
3. Determine target: PR URL, branch diff, or staged changes
4. Resolve topic: derive from branch name (`feat/foo` -> `foo`), explicit `--topic`, or repo name. Create `~/.agents/artifacts/<topic>/` if missing.

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

Present findings in chat, then persist to `~/.agents/artifacts/<topic>/review.md`:

```
---
topic: <slug>
repo: <repo-name>
branch: <branch>
date: <YYYY-MM-DD>
---
## <filename>

- [severity] finding. <explanation>
  suggestion: <concrete fix>
```

Severities: `blocker`, `issue`, `nit`, `question`.

On write failure (permissions, disk): warn in chat, continue. The review is still delivered in the conversation.

Headless/pipeline reviews use the `review` CLI (Codex) which writes the same artifact shape.

## Principles

- Blockers first, nits last
- Concrete suggestions, not vague feedback
- Don't flag style issues covered by linters/formatters
- Acknowledge good patterns -- not everything needs a comment
- If the diff is large, focus on the riskiest changes
- Route process/tooling lessons into `## Future learnings` rather than mixing them with code findings

## Next

On completion, print: `🦊 Review at <path>. Blockers? Fix and re-checkpoint`
