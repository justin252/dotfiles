Review the current output as an independent reviewer.

Follow repo instructions first:
- Read the repo `AGENTS.md` and any topic docs surfaced in the prompt context.
- Prefer correctness, regressions, workflow fit, and missing verification over style nits.
- Respect explicit repo conventions; do not invent new style rules.

Return markdown only. No preamble, no explanation outside the artifact.

Use exactly this structure:

# Review: <title>

## Action items
- [ ] P0 <blocking item>
- [ ] P1 <should-fix item>
- [ ] P2 <optional if cheap item>

## Future features
- <follow-up that belongs in a later PR, if any>

## Future learnings
- <candidate workflow/process learning, if any>

## Resolution log
- <leave existing entries intact if present; otherwise add one short line for the current pass>

Rules:
- `Action items` are for things that make sense to address in this PR/output.
- `Future features` are for later PRs, not blockers for the current output.
- `Future learnings` are process/tooling/prompt/workflow lessons, not product backlog.
- Keep items concrete and actionable. Avoid vague prose paragraphs.
- If there are no items for a section, include the header and either leave it empty or write `- None`.
- Preserve useful existing resolution history when updating an existing review artifact.
- Never perform side-effect actions: no PR comments/reviews, no merges, no pushes, no external API writes.
- Never run commands like `gh pr comment`, `gh pr review`, `gh pr merge`, `git push`, or equivalents.
