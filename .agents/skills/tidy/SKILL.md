---
name: tidy
description: "🦫 Diagnose and fix branch/stack health. Run before pushing, or as /checkpoint pre-flight. Use when the user says 'tidy', 'check my branch', 'fix my stack', 'is this clean', or before shipping."
---

# /tidy

Read-only diagnosis by default. `tidy fix` for active repair. Always safe to run.

## Bootstrap

1. Determine target: current branch (default), PR number(s), or `--stack <name>`
2. Detect Graphite: `gt log short --stack 2>/dev/null` – if it works, include stack context
3. Detect topic: derive from branch name (`feat/foo` → `foo`), check for `~/.agents/artifacts/<topic>/plan.md`

## Checks

### P0 – blocks (must fix before push)

1. **Branch guard** – `git branch --show-current` matches intended work. On `main`/`master` → abort.
2. **Staged file audit** – `git diff --cached --stat`. Flag files outside this branch's concern. If topic has `plan.md` or `output.md`, compare staged files against stated scope.
3. **Unstaged leak detection** – `git diff --stat`. Changes that look like they belong on a different branch (different directory, different concern). Suggest which branch they might belong on.
4. **Stack position** – if in a Graphite stack, verify parent branch's changes are present. `git log --oneline HEAD..$(gt log short --stack | head -2 | tail -1) 2>/dev/null` – if parent has commits not in current, base is stale.

### P1 – warns (should fix)

5. **Behind main** – `git rev-list --count HEAD..origin/main`. If >0, estimate conflict risk: `git merge-tree $(git merge-base HEAD origin/main) HEAD origin/main 2>/dev/null` or simpler heuristic (same files changed?).
6. **Scope check** – if `~/.agents/artifacts/<topic>/plan.md` or `output.md` exists, diff file list against stated intent. Flag changes not mentioned in plan.
7. **CI status** – if branch has a PR, `gh pr checks` for failing checks. Skip if no PR.

### P2 – info

8. **Change summary** – `git diff --stat` grouped by directory/concern. Show total lines changed. If large diff, highlight the biggest files.

## Output Format

```
🦫 /tidy

  Branch: feat/add-feature
  Stack: refactor/base → feat/add-feature → fix/edge  (Graphite)
  Base: origin/main (3 behind)

  ── P0 ──────────────────────────────
  ✓ Branch: feat/add-feature (matches topic)
  ✓ Staged: 4 files, all in scope
  ✗ Unstaged: shell/zshrc.work has changes (belongs on chore/shell-cleanup?)
  ✓ Stack parent: up to date

  ── P1 ──────────────────────────────
  ⚠ 3 commits behind main (no conflicting files – clean rebase)
  ✓ Changes match plan.md scope
  ✓ CI: all passing (PR #42)

  ── Changes ─────────────────────────
  agents/skills/tidy/   +95 (new skill)
  agents/docs/circus.md  +3 -3 (name update)
  install.sh              +1 (learnings dir)

  Result: 1 issue (P0). Run /tidy fix or fix manually.
```

If everything is clean: `🦫 All clear. Ready to push.`

## Fix Mode (`/tidy fix`)

Only when explicitly invoked. Show what will happen, then execute:

- **Unstaged leaks** → `git stash push -m "tidy: parked for <branch>" -- <files>`. Print stash ref.
- **Wrong files staged** → `git restore --staged <file>`. Print which files unstaged.
- **Behind main** → `git rebase origin/main` (or `gt restack` if Graphite stack). Print result.
- **Stale stack base** → `gt restack`. Print result.
- **Conflicts or code issues** → don't attempt. Print: "Conflicts detected. Run `/execute` to resolve."

Never: `git reset --hard`, `git checkout .`, `git clean`, `git branch -D`, `gt submit`.

## Safety

- Default mode is pure read-only. Runs git queries, prints output, changes nothing.
- Fix mode only uses reversible operations (stash, unstage, rebase).
- Stash before rebase if working directory is dirty.
- Never touches the Graphite stack ordering – only restacks.
- Never pushes – that's checkpoint's job.

## Epilogue

Append 1-3 lines to `~/.agents/circus/beaver.md`: common issues found, fix patterns that worked, false positives to suppress.

## Next

On completion, print one of:

If clean: `🦫 All clear. Ready for /checkpoint`
If issues found: `🦫 N issues. /tidy fix to repair, or fix manually.`
If fixed: `🦫 Fixed N issues. Ready for /checkpoint`
