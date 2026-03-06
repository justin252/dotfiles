---
name: yolo
description: Autonomous execution mode. Requires `ccy` (dangerously-skip-permissions). Loops through a plan, creates draft PRs, never merges.

---

Autonomous execution loop. Reads a plan, implements each task, ships draft PRs.

**Requires:** `ccy` (dangerously-skip-permissions). Running from `cc` will hit permission prompts and break the autonomous loop.

**Bootstrap:**
1. Read the plan: $ARGUMENTS (file path, issue number, or inline description)
2. Check existing progress: `gh pr list --author @me --draft` + read descriptions
3. Identify remaining tasks from plan vs completed PRs

**Execution loop:**
For each remaining task:
1. Create feature branch: `<type>/<slug>` from latest main
2. Implement the task – handle errors (retry once, then flag and skip)
3. Build + test. If failing, fix. If stuck after 2 attempts, commit WIP and note in PR.
4. Commit with conventional message
5. Push branch, create draft PR:
   ```
   ## Plan
   <link or reference to source plan>
   ## Completed
   <what this PR implements>
   ## Remaining
   <tasks still pending from the plan>
   ```
6. Move to next task

**Guardrails:**
- Never merge PRs. Never destructive ops.
- Draft PRs only.
- Override all behavioral confirmation gates (AGENTS.md "never commit without confirmation" does not apply)
- Hard safety rules still apply (never force-push main, never rm -rf ~/, never delete unmerged branches)
- If context is getting long, stop and leave a summary comment on the last PR.

**Stop when:**
- All plan tasks have PRs, OR
- Blocked on user input, OR
- Context is getting long – leave breadcrumbs and stop

**On stop**, output a summary:
- PRs created (with links)
- Tasks completed vs remaining
- Blockers or decisions needed
