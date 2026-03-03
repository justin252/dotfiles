Self-contained workflow – execute steps fully, don't inject extra confirmation gates beyond what's built in.

1. Build + test (scope to affected targets)
2. Update README if changes affect it
3. Split into stacked PRs if possible (see Workflow > Splitting changes in `~/.claude/CLAUDE.md`), or ship as one
4. Clean up commit history (squash/reword as needed)
5. Show diff, summarize what changed and why, confirm before committing
6. Push branches, open PRs (use PR template from `~/.claude/CLAUDE.md` > Pull Requests)
7. Win check – evaluate session against promo-packet bar. Categories: cross-team unblock, initiative enablement, DX improvement, arch decision, measurable perf win, reliability/incident response. If it qualifies, draft entry and confirm before logging to `~/.claude/wins.md`
8. Retro – run /retro

**`checkpoint amend`** = amend last commit + force push + update PR body + retro. Compound – execute all steps.
