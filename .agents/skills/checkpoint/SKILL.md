---
name: checkpoint
description: Build, test, split/ship PRs, commit, push, async review handoff, win check, retro. The only release path.
---

Self-contained workflow -- execute steps fully, don't inject extra confirmation gates.

## Steps

0. **Branch guard**: if `git branch --show-current` is main or master, abort: "create a feature branch first – all changes to main require a PR"
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
9. **Async review**: if the topic has `output.md` or a current output entry in `plan.md`, launch `review --topic <topic>` after push/PR. Surface the log path and review artifact path.
10. **Session summary**: if significant work was done (commits, artifacts created/updated, PRs opened), save a session summary to `~/.agents/sessions/<slug>.md`. Slug = branch name or topic. Frontmatter: topic, repo, date. Sections: What I was doing, Key decisions, Current state, Unresolved. Skip for trivial changes (typo, config tweak).
11. **Retro**: run /retro (mandatory epilogue, not a confirmation gate – always execute)

**`checkpoint amend`** = amend last commit + force push + update PR body + async review handoff + retro.
