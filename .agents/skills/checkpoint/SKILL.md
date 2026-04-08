---
name: checkpoint
description: "🦅 Build, test, split/ship PRs, commit, push, async review handoff, win check, retro. The only release path."
---

Self-contained workflow -- execute steps fully, don't inject extra confirmation gates.

**Bazel server lock**: When another agent is building on the same workspace, Bazel waits 30-120s for the server lock. This is normal queue behavior, not a hang. Do not kill and retry.

## Steps

0. **State guard**: check for in-progress rebase (`-d .git/rebase-merge` or `-d .git/rebase-apply`) or merge (`-f .git/MERGE_HEAD`). If found, abort: "finish or abort the rebase/merge first."
1. **Tidy**: run `/tidy` to diagnose branch/stack health. If P0 issues found, run `/tidy fix` before continuing. This handles branch guard, staged file audit, unstaged leaks, stack health, and scope check.
2. **Build + test**: scope to affected targets. Skip if:
   - Docs-only change (no source files modified)
   - Tests already passed this session (TDD workflow -- don't re-run)
   - Pure config change (no executable code modified). Note: shell scripts and tools ARE executable code – always test those
3. **Work overlay**: if AGENTS-work.md § Checkpoint is loaded, run its additional pre-push steps now.
4. **README**: update if changes affect it
5. **Config review**: if any config files changed (CLAUDE.md, settings.json, zshrc, AGENTS.md), summarize what changed and why before committing
6. **Commit + push + PR**: squash/reword history before the first push – not after. Show diff, summarize, confirm before committing. Before pushing, verify PR state: `gh pr view --json state -q .state` – if `MERGED`, abort with "PR already merged; create a new branch." Push and create/update PR. Use Graphite only when repo-level config enables it; default to git+gh. Always `--draft`.

   PR body: follow AGENTS-work.md § PR Descriptions if loaded, otherwise AGENTS.md § Pull Requests.

7. **Win check**: does this session clear the promo-packet bar? Categories: cross-team unblock, DX improvement, arch decision, measurable perf win, reliability/incident. If yes, draft entry, confirm, log to `~/.agents/wins.md`
8. **Async review**: if the topic has `output.md` or a current output entry in `plan.md`, launch `review --topic <topic>` after push/PR. Surface the log path and review artifact path.
9. **Session summary**: if significant work was done (commits, artifacts created/updated, PRs opened), save a session summary to `~/.agents/sessions/<slug>.md`. Slug = branch name or topic. Frontmatter: topic, repo, date. Sections: What I was doing, Key decisions, Current state, Unresolved. Skip for trivial changes (typo, config tweak).
10. **Retro**: run /retro (mandatory epilogue, not a confirmation gate – always execute)

**`checkpoint amend`** = amend last commit + force push + update PR body + async review handoff + retro.

## Epilogue

Append 1-3 lines to `~/.agents/circus/beaver.md`: what shipping patterns worked, build/test issues hit, PR splitting decisions.

## Next

After completion, print one of:

If async review was launched (step 8):
```
🦉 Review launched (async)
  tail -f ~/.agents/artifacts/<topic>/review-run.log
  review --status
  cat ~/.agents/artifacts/<topic>/review.md
```

If no review launched:
```
🦉 PR open: <url>. Next: review <topic> or wait for pipeline
```
