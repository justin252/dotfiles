---
description: Wrap up current work — build, test, split PRs, commit, push, retro
argument-hint: [amend]
disable-model-invocation: true
---

# /checkpoint $ARGUMENTS

Save progress — build, test, commit, push draft PR, retro.

Runs frequently: trigger anytime to save work, or auto-triggers at end of a workflow. Default to **draft PRs** for safety.

If **$ARGUMENTS** is "amend", skip to the amend workflow below.

## Steps

Execute fully — no extra confirmation gates beyond what's listed.

1. **Build + test** — run relevant tests for changed code
2. **Update README** if changes affect it
3. **Split into stacked PRs** if changes are separable (see Splitting below), otherwise ship as one
4. **Clean up commits** — squash/reword as needed
5. **Show diff + summarize** — confirm with user before committing
6. **Push + open draft PR** — use global PR template from CLAUDE.md
7. **Win check** — does this session clear promo-packet bar? If yes, draft entry for `~/.claude/wins.md`, confirm before logging
8. **Retro** → `/retro`

## Amend variant

`/checkpoint amend` — compound command, execute all:

1. Amend last commit
2. Force push
3. Update PR body (`gh pr view --json body` first — never overwrite blindly)
4. Retro

## Splitting changes

Prefer splitting logically independent changes (refactor, bug fix, feature) into stacked PRs.

**Proactive (preferred):** Recognize a separable change while working → branch + commit immediately before continuing.

**Retroactive:** Changes already mixed → attempt to untangle (split commits, cherry-pick, rebase). If too intertwined, ship as one PR and flag it — don't butcher the split.

Stack order: foundational changes first (refactors, fixes), dependent features on top. Each PR targets the branch below it (or main for the first).
