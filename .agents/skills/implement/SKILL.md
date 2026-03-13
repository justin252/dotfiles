---
name: implement
description: Execute phased implementation plans. Creates or reads ~/documents/<topic>/impl.md, works through phases with testable checkpoints. Use when the user wants to implement something, execute a plan, build a feature, or says 'implement', 'build this', 'execute', 'impl'.
---

# /implement

Execute a phased implementation plan. Each phase is independently valuable and testable.

## Bootstrap

1. Read `~/.agents/AGENTS.md` for conventions (commit style, PR template, safety rules)
2. Determine the topic: $ARGUMENTS, or infer from conversation context
3. Check `~/documents/<topic>/impl.md`:
   - **Exists**: read it, find the next unchecked phase, resume there
   - **Missing**: create it. If an RFC exists (`~/documents/<topic>/rfc.md`), derive phases from it. Otherwise, draft phases from the task description.
4. Confirm the plan with the user before executing (skip in autonomous mode)

## Impl Doc Format

```markdown
---
status: in-progress
created: YYYY-MM-DD
---

# <Topic> – Implementation Plan

Source: [rfc](../rfc.md) (if exists)

## Phase N: <Name>

<Description of what this phase accomplishes>

- [ ] Task 1
- [ ] Task 2
- [ ] **Validate**: <test criteria>
```

Each phase: description, task checkboxes, validation criteria at the end.

## Execution

For each phase:
1. Read the phase tasks
2. Work through them sequentially
3. Check off tasks as completed (edit the impl.md)
4. Add references inline (PR links, test output, file paths)
5. At phase end: run validation criteria
6. **Stop and report** -- let the user validate before continuing to next phase

When a phase is done, update its checkboxes and add a completion note:

```markdown
- [x] Task 1 – [PR #123](url)
- [x] Task 2
- [x] **Validate**: passed – `source ~/.zshrc` clean, `wt --help` works
```

## Execution Modes

Default is interactive. User can request a different mode:

- **interactive** (default): work through tasks, confirm at logical boundaries, stop at phase end
- **autonomous**: execute all remaining phases. Draft PRs, never merge. Stop on failure or ambiguity. Override confirmation gates except safety rules.
- **teach**: narrate every change. Explain how each diff fits the plan, highlight idioms and gotchas. Approve each logical unit before proceeding.

## Conventions (self-contained for subagent isolation)

These duplicate AGENTS.md essentials so CC subagents work without inheriting parent context:

- **Commits**: conventional (`feat:`, `fix:`, `chore:`, `refactor:`). Single-line subject, no body.
- **Branches**: `<type>/<slug>` (e.g. `feat/add-grep-tool`)
- **PRs**: always `--draft`. Body: Motivation, Summary, Test plan.
- **Stacking**: check repo-level AGENTS.md for stacking preference. Default: `git push -u` + `gh pr create --draft`. Use Graphite (`gt create`, `gt submit --draft`, `gt restack`) only when repo config explicitly enables it.
- **Safety**: never force-push main, never rm -rf outside build dirs, never delete unmerged branches.
- **Checkpoint**: route through /checkpoint skill for push/PR. Never bare push.

## Stacking

If a phase maps cleanly to a PR, create the branch and commit at phase end. Prefer stacked PRs for multi-phase work. Each PR must be independently correct. Use Graphite only when repo-level config enables it; default to git+gh.

## Completion

When all phases are checked off:
1. Update impl.md frontmatter: `status: done`
2. If an RFC exists, update its status too
3. Run /retro to capture session learnings
