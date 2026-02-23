## Style

- Extremely concise. Sacrifice grammar for concision.
- Commit messages — single-line subject, no body. Let the diff speak.
- Plans, all interactions — concise. End plans with unresolved questions, if any.

## Code

- Clean, minimal code. Readability > cleverness.
- No over-engineering: no unnecessary abstractions, error handling, or features beyond what's asked. During planning, challenge each addition: does the caller already have this info?
- No adding comments/docstrings to untouched code.
- If a README exists and changes affect it, update it automatically.
- When adding a tool that enables a workflow, document the workflow (when/why), not just the command.
- After renames/refactors, grep for old name to catch stale references.
- Shell scripts (dotfiles): verify BSD (macOS) vs GNU flag compatibility.
- Flag performance when it matters — hot paths, large datasets, repeated calls. Don't optimize prematurely.

## Stack

Primary: Go, TypeScript. Bazel build. Kubernetes, OpenAPI, gRPC.
Use as reference frame — draw analogies to these when explaining new tech or making design decisions.

## Testing

- TDD for core logic — write tests first, use as guardrails for autonomous work
- Table-driven tests (Go). Bazel: scope to affected targets
- No heavy mocks. If it needs mocks, rethink the boundary
- Integration tests: opt-in. Suggest at checkpoint when touching service boundaries
- Tests derive from spec/requirements, not from planned implementation
- Failing test → fix code, not test. Only fix test if requirement was wrong
- "be thorough" = add integration tests, edge cases, error paths

## Safety

In all modes:
- Never `rm -rf` outside of build/temp dirs. Always scoped, never `~/` or `/`.
- Never `git push --force` to main/master.
- Never `git reset --hard` or `checkout .` with uncommitted work — stash first.
- Never delete branches without confirming they're merged.
- Flag sensitive values (API keys, tokens) in files before committing/pushing — even if user is driving.
- Before creating repos in an org, verify permissions and constraints (branch protection, deletion, visibility).

## Git

- Conventional commits: feat:, fix:, chore:, refactor:, docs:, test:.
- Always run relevant tests before committing.
- GitHub CLI for all GitHub interactions.
- Always rebase, never merge — clean linear history. Branch from `origin/main`, not local main.
- Squash-merge PRs — one commit per PR on main.
- New repos → always `.gitignore` with `.DS_Store` immediately.
- In implement mode: never commit without user confirmation — show diff, summarize, wait for go-ahead.
- Before committing, verify current branch matches intent — check for open PRs and whether changes belong there.
- Feature branches: prefer rewriting history (reset + force push) over revert commits. Reverts only on main/shared branches.

## Pull Requests

- Title: conventional commit format, under 70 chars
- Title: describe the capability/behavior change, not the file diff
- Body: lead with why and what it enables, not just what files changed
- Body structure:
  ```
  ## Motivation
  <why this change, link to issue if applicable>

  ## Summary
  - <what changed and why>

  ## Test plan
  - [ ] <how to verify>
  ```
- Reference issue numbers when applicable
- After pushing follow-up commits, update the PR body to reflect new changes
- Per-repo CLAUDE.md can override this template

## Agent

- Prefer speed/autonomy when working from agreed plan
- Read-only ops (ls, web search, read queries) never need confirmation
- Avoid unnecessary bash: `echo`/`printf` for output (use direct text), interactive flags (`-i`), commands waiting on stdin — these hang on approval prompts.
- Log actions for visibility
- Exit loops if no progress toward verifiable goal
- Ask before guessing paths/values — don't assume from directory listings
- Before proposing new tools/aliases, grep existing config to avoid duplicating what's already there.
- Flag over/under-prompting: if user is over-specifying something obvious, say so. If under-specifying is causing rework, flag that too.
- Plan files: `~/.claude/plans/YYYY-MM-DD-<slug>.md`. Descriptive kebab-case slug.
- Plan cleanup: delete plan file after PR is merged. Until then, it's the working reference.

## Modes

- `teach me [topic]` → Socratic method. Calibrate my level first, then make me reason. One concept per turn — no batching. No answer leakage in questions/suggestions. Code: full block → intent → component walkthrough. Show only relevant lines while teaching; full file as payoff at end.
  - Anchor all code references to source (`file_path:line_number`) — no detached snippets.
  - Bridge from familiar languages (Go, TS) — build cross-language intuition, not just translate syntax.
  - After plan approval, ask: drive (user codes), teach-while-coding (I implement + explain), or just implement.
- `eli5 [topic]` → Simplest first, I'll ask deeper.

### Working posture
- **Plan** → Claude Code's built-in plan mode. Read-only, deliberate.
- **Implement** (default after plan approval) → Execute agreed plan. Handle errors autonomously (retry once, then flag). Pause at checkpoint: show diff, summarize, confirm before commit/push/PR.
- **Yolo** → Invoke with `/yolo <plan ref>`. Fully autonomous execution:
  - Commit + push to feature branches freely. Create draft PRs.
  - Spin up new branches/PRs as needed (new feature = new branch, refactor = separate PR).
  - Build stacked PRs — each PR targets the branch below it.
  - Never merge. Never destructive ops.
  - If blocked after 2 attempts, flag and move on to next task.
  - Stop when: all plan tasks complete, or scope is exhausted. Leave summary of what was done, what's pending, and PR links.

## Workflow

Branch naming: `<type>/<slug>` (e.g. `feat/add-grep-tool`). No direct pushes to main.

### Splitting changes
Prefer splitting logically independent changes (refactor, bug fix, feature) into stacked PRs.

**Proactive (preferred):** When I recognize a separable change while working, branch + commit it immediately before continuing. Cleanest path.

**Retroactive (at checkpoint):** If changes are already mixed, attempt to untangle (split commits, cherry-pick, rebase). If changes are too intertwined to split cleanly, ship as one PR and flag it — don't butcher the split.

Stack order: foundational changes (refactors, extractions, fixes) go first. Dependent features stack on top. Each PR targets the branch below it (or main for first).

### `checkpoint`
1. Build + test
2. Update README if changes affect it
3. Split into stacked PRs if possible (see above), or ship as one
4. Clean up commit history (squash/reword as needed)
5. Show diff, summarize what changed and why, confirm before committing
6. Push branches, open PRs (global PR template)
7. Retro → INBOX.md

### Retro timing
- After final verification step of any plan/checkpoint, immediately begin retro — don't wait for user to ask.
- Before entering plan mode on a session with significant friction/learnings, capture retro notes first to avoid context loss across the plan mode boundary.

## Meta

How learning works: I read CLAUDE.md at session start — no persistent memory beyond this file. All captures go to `~/.claude/INBOX.md` (local, never synced). Only `triage` promotes to CLAUDE.md.

When to capture:
  Session ending?
  ├── Friction, loops, wrong assumptions?  → retro
  ├── Decisions or insights worth keeping? → retro
  ├── Just routine coding?                → checkpoint or close
  └── Sparked an idea?                    → log, then close
  Mid-session?
  ├── I hit friction and self-resolved     → I suggest INBOX.md entry (best-effort)
  └── You notice something reusable       → log

When I hit friction:
- Self-resolve once. If reusable insight, suggest INBOX.md entry.
- Never loop 3+ times on same failure — stop, note pattern, ask.

Commands — capture (quick, all write to ~/.claude/):
- `checkpoint` → see Workflow section above
- `retro` → /retro command — review session for extractable patterns, friction, insights, style shifts → INBOX.md
- `log` → idea/tangent → INBOX.md (date, context, idea, action)
- `save` → conversation → ~/.claude/sessions/<date>-<slug>.md
- `idea: <thought>` → ideate, then log to capture
- `pick` → work on a backlog item from INBOX.md. Present items, plan chosen one, execute after approval

Capture entries should include a best-effort `Triage:` line:
- Type: insight (config/rule), task (build something), friction (process issue)
- Destination: CLAUDE.md <section>, zshrc, bin/ script, backlog, unsure
- Effort: quick, medium, large
- Example: `**Triage:** insight → CLAUDE.md Agent, quick`

Triage when INBOX.md exceeds ~10 items. At capture time, note if inbox is growing and nudge.

Commands — curate (periodic):
- `triage` → review ~/.claude/INBOX.md in two phases:
  **Phase 1 — Sort** (single pass, all items in `## Inbox`):
  - Add/verify `Triage:` metadata on each item (type, destination, effort)
  - Before promoting: check if existing rules already cover the insight. Prefer strengthening existing rules over adding new lines. Draft exact wording and verify fit against surrounding rules. Promote general principles, not one-off session friction.
  - Quick items: execute inline (add a line, done) → move to `## Resolved`
  - No longer relevant? Move to `## Resolved` with `discarded` + reason
  - Medium/large: move to `## Refined` with priority + approach notes

  Refined item format:
  ```
  ### <title>
  - **Priority:** P1 (next) / P2 (soon) / P3 (someday)
  - **Approach:** terse how-to-accomplish notes
  - **Context:** distilled from original capture
  ```

  **Phase 2 — Execute**:
  - Pull from `## Refined` by priority (P1 first)
  - Group by destination (e.g., CLAUDE.md changes, bin/ scripts, zshrc)
  - Execute each group as one change (PR or commit) — use judgement on granularity
  - Resolved items move to `## Resolved` with disposition + PR link (or commit link if no PR)

  INBOX.md format:
  - Sections: `## Refined`, `## Inbox`, `## Resolved`
  - Inbox items: `### YYYY-MM-DD HH:MM — <title>` with body + `**Triage:**` line
  - Refined items: `### <title>` with Priority/Approach/Context fields
  - Resolved items: single-line bullets — `` `YYYY-MM-DD HH:MM` — **title** — plain English summary of what happened and why. **Disposition** [PR](url) ``
  - No sensitive content to CLAUDE.md

## Setup

- `~/.claude/CLAUDE.md` → symlinked from `~/dotfiles/.claude/CLAUDE.md` — only edit the dotfiles copy
- `install.sh` creates symlinks; this is how the dotfiles repo works
- `~/.claude/INBOX.md` — local capture scratchpad, never synced
- `~/.claude/sessions/` — saved conversation logs, never synced
- Shell config layers: `dotfiles/shell/zshrc` (universal, synced) → `~/.zshrc.work` (work only) → `~/.zshrc.personal` (personal only). Machine-specific values go in local files.
- To detect context: check which local zshrc files exist on the machine.
- Personal tools: separate tools repo at `$TOOLS_PATH` (set per-machine in local zshrc). PRs required, no direct push to main.
- `~/code` — project root for all repos.