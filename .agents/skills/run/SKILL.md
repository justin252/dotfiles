---
name: run
description: "🦁 Full autonomous pipeline: plan.md to PR. Composes /execute, /checkpoint, async review, and /retro. Use when dispatched via `ag run <topic>` or when the user says 'run', 'full pipeline', 'ship this plan'."
---

# /run

🦁 The ringmaster. Full pipeline: plan.md in, PR + review.md + INBOX entries out. No human gates except merge.

At scale, 🦁 dispatches multiple `/run` pipelines in parallel. Today, each `ag run` is one 🦁 pipeline.

## Bootstrap

1. Read `~/.agents/AGENTS.md` for conventions
2. Determine plan path:
   - Explicit arg: `/run <plan-path>` or `/run <topic-slug>`
   - Topic slug resolves to `~/.agents/artifacts/<slug>/plan.md`
   - Fail if no plan.md found
3. Read plan.md. Verify it has unchecked phases. Read ## Open; if non-empty, log each item to INBOX.md as a design decision the implementer should be aware of.
4. Derive topic slug from plan path (parent dir name)
5. Write phase state: `~/.agents/state/<slug>/phase` ← "starting"

## Pipeline

Execute these stages in order. Write phase state at each transition.

### Stage 1: 🦊 Execute

Phase state: "executing"

Follow `/execute` skill in **autonomous** mode:
- Read `~/.agents/skills/execute/SKILL.md`
- Execute all phases from plan.md without stopping for confirmation
- Check off tasks as completed
- Stop on failure or ambiguity (report what went wrong)

### Stage 2: 🦅 Ship

Phase state: "shipping"

Follow `/checkpoint` skill:
- Read `~/.agents/skills/checkpoint/SKILL.md`
- Build, test, PR, output.md
- Skip confirmation gates (autonomous context)
- Record the PR URL for later stages

### Stage 3: 🦉 Review

Phase state: "reviewing"

Kick off async review:
```bash
review --topic <slug>
```

Then poll for completion:
```bash
review --status <slug> --json
```
Check every 30 seconds. Timeout after 10 minutes (review tool handles its own failures).

When review completes, read `~/.agents/artifacts/<slug>/review.md`.

### Stage 4: 🔧 Fix (conditional)

Phase state: "fixing"

If review.md contains `blocker` or `issue` severity findings:
1. Read each finding
2. Apply fixes
3. Re-run /checkpoint (amend + force push + update PR)
4. **Do not re-review.** One fix cycle max.

If review.md is clean (only `nit` or `question`), skip this stage.

### Stage 5: 🐘 Learn

Phase state: "learning"

Run `/retro` (full mode):
- Read `~/.agents/skills/retro/SKILL.md`
- Scan all categories
- Extract `## Future learnings` from review.md into INBOX.md
- Check INBOX.md size; nudge toward /triage if >10 items

### Stage 6: ✅ Done

Phase state: "done"

Print summary:
```
🎪 /run complete: <topic>
  🦅 PR: <url>
  🦉 Review: <status> (<review-path>)
  🐘 INBOX: <N> items captured
  📋 Plan: all phases checked
```

Notify via available mechanisms:
- `tput bel` (terminal bell)
- `tmux display-message "/run done: <topic>"` if in tmux

## Phase State

Write current phase to `~/.agents/state/<slug>/phase` at each transition. This file is read by `ag status` and `ag-status-line` for observability.

```bash
mkdir -p ~/.agents/state/<slug>
echo "executing" > ~/.agents/state/<slug>/phase
```

## Crash Recovery

If resuming a crashed /run session:
1. Check plan.md for checked-off phases (execution progress)
2. Check git log / PR state (shipping progress)
3. Check review-state.json (review progress)
4. Resume from the last incomplete stage

## Conventions (self-contained for subagent isolation)

- **Commits**: conventional (`feat:`, `fix:`, `chore:`, `refactor:`). Single-line subject, no body.
- **Branches**: `<type>/<slug>` (e.g. `feat/add-grep-tool`)
- **PRs**: always `--draft` unless repo AGENTS.md says otherwise. Body: Motivation, Summary, Test plan.
- **Safety**: never force-push main, never rm -rf outside build dirs, never delete unmerged branches.
- **Checkpoint**: route through /checkpoint skill. Never bare push.
