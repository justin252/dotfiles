---
name: execute
description: "🦊 Execute phased implementation plans. Creates or reads ~/.agents/artifacts/<topic>/plan.md, works through phases with testable checkpoints. Use when the user wants to implement something, execute a plan, build a feature, or says 'execute', 'build this', 'implement', 'exec'."
---

# /execute

Execute a phased plan. Each phase is independently valuable and testable.

## Launch

Preferred: `ag <name> -m "/execute from ~/.agents/artifacts/<topic>/plan.md"` (auto-creates worktree, autonomous).
Or via `artifacts` → pick plan → execute action.
Can also run inline in an existing claude session.

## Bootstrap

1. Read `~/.agents/AGENTS.md` for conventions (commit style, PR template, safety rules)
2. Determine the topic: $ARGUMENTS, or infer from conversation context
3. Check `~/.agents/artifacts/<topic>/`:
   - **plan.md exists**: read it, find the next unchecked phase, inspect `output.md`/`review.md` if present, resume there
   - **No plan.md but design.md exists**: derive plan.md from design. Read ## Open sections from problem.md/design.md first – append unresolved items as phase 0 decisions.
   - **Nothing exists**: draft plan.md from task description.
4. Confirm the plan with the user before executing (skip in autonomous mode)

## Plan Doc Format

See `~/.agents/conventions/artifact-templates.md` for the canonical template. Key structure:

```markdown
---
topic: <slug>
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
chain: problem.md → design.md → **plan.md**
---
# Plan: <title>

## Outputs
- [ ] current-output – current | planned | shipped. Branch/PR/review refs when known.

## Phase N: <Name>
- [ ] Task 1
- [ ] Task 2
- [ ] **Verify**: <test criteria>

## Open
- [ ] <unresolved questions>
```

## Workspace Contention

**Bazel server lock**: Bazel uses a single server per workspace. When another agent is building, you may see 30-120s waits for the lock. This is normal queue behavior, not a hang. Do not kill and retry.

## Execution

For each phase:
1. Read the phase tasks
2. Work through them sequentially
3. Check off tasks as completed (edit the plan.md)
4. Keep `output.md` current for the active deliverable; add branch/PR/review refs when known
5. Add references inline (PR links, test output, file paths)
6. At phase end: run validation criteria
7. **Stop and report** – let the user validate before continuing to next phase

When a phase is done, update its checkboxes and add a completion note:

```markdown
- [x] Task 1 – [PR #123](url)
- [x] Task 2
- [x] **Verify**: passed – `source ~/.zshrc` clean, `wt --help` works
```

## Execution Modes

Default is interactive. User can request a different mode:

- **interactive** (default): work through tasks, confirm at logical boundaries, stop at phase end
- **autonomous**: execute all remaining phases. Draft PRs, never merge. Stop on failure or ambiguity. Override confirmation gates except safety rules.
- **teach**: narrate every change. Explain how each diff fits the plan, highlight idioms and gotchas. Approve each logical unit before proceeding.

## Conventions (self-contained for subagent isolation)

These duplicate AGENTS.md essentials so subagents work without inheriting parent context:

- **Commits**: conventional (`feat:`, `fix:`, `chore:`, `refactor:`). Single-line subject, no body.
- **Branches**: `<type>/<slug>` (e.g. `feat/add-grep-tool`)
- **PRs**: always `--draft`. Body: Motivation, Summary, Test plan.
- **Stacking**: check repo-level AGENTS.md for stacking preference. Default: `git push -u` + `gh pr create --draft`. Use Graphite (`gt create`, `gt submit --draft`, `gt restack`) only when repo config explicitly enables it.
- **Safety**: never force-push main, never rm -rf outside build dirs, never delete unmerged branches.
- **Checkpoint**: route through /checkpoint skill for push/PR + async review. Never bare push.

## Stacking

If a phase maps cleanly to a PR, create the branch and commit at phase end. Prefer stacked PRs for multi-phase work. Each PR must be independently correct. Use Graphite only when repo-level config enables it; default to git+gh.

## Completion

When all phases are checked off:
1. Update plan.md frontmatter: `status: done`
2. If problem.md/design.md exist, update their status too
3. Run /retro to capture session learnings
