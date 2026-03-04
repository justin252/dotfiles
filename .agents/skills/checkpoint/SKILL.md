---
name: checkpoint
description: Build, test, split/ship PRs, commit, push, win check, retro. The only release path.

---

Self-contained workflow – execute steps fully, don't inject extra confirmation gates beyond what's built in.

1. Build + test (scope to affected targets)
2. Update README if changes affect it
3. Split into stacked PRs if possible (see Workflow > Splitting changes in AGENTS.md), or ship as one
4. Clean up commit history (squash/reword as needed)
5. Show diff, summarize what changed and why, confirm before committing
6. Push branches, open PRs (use PR template from `~/.agents/AGENTS.md` > Pull Requests)
7. Win check – evaluate session against promo-packet bar (see below). If it qualifies, draft entry and confirm before logging to `~/.agents/wins.md`
8. Retro – run /retro

**`checkpoint amend`** = amend last commit + force push + update PR body + retro. Compound – execute all steps.

**Win bar** (step 7): promo-packet worthy – impact beyond the code change. Categories: cross-team unblock, initiative enablement, DX improvement, arch decision, measurable perf win, reliability/incident response. When Jira/initiative context is shared, use it to frame impact. Auto-detect suggests entry, user confirms.
