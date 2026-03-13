---
name: checkpoint
description: Build, test, split/ship PRs, commit, push, win check, retro. The only release path.
---

Self-contained workflow -- execute steps fully, don't inject extra confirmation gates.

## Steps

1. **Assess scope**: `git diff --stat` to understand what changed
2. **Build + test**: scope to affected targets. Skip if:
   - Docs-only change (no source files modified)
   - Tests already passed this session (TDD workflow -- don't re-run)
   - Dotfiles/config-only change (no build system)
3. **README**: update if changes affect it
4. **Split or ship**: split into stacked PRs if logically independent changes exist, otherwise ship as one. Use Graphite only when repo-level config enables it; default to git+gh.
5. **Config review**: if any config files changed (CLAUDE.md, settings.json, zshrc, AGENTS.md), summarize what changed and why before committing
6. **Commit**: clean up history (squash/reword). Show diff, summarize, confirm before committing
7. **Push + PR**: use PR template from AGENTS.md. Always `--draft`.

   PR body:
   ```
   ## Motivation
   <why, link issue if applicable>

   ## Summary
   - <what changed and why>

   ## Test plan
   - [ ] <verification steps>
   ```

8. **Win check**: does this session clear the promo-packet bar? Categories: cross-team unblock, DX improvement, arch decision, measurable perf win, reliability/incident. If yes, draft entry, confirm, log to `~/.agents/wins.md`
9. **Retro**: run /retro (mandatory epilogue, not a confirmation gate – always execute)

**`checkpoint amend`** = amend last commit + force push + update PR body + retro.
