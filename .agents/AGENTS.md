## Style

- Extremely concise. Sacrifice grammar for concision.
- No em dashes (—). Use en dashes (–), semicolons, or restructure.
- Commit messages – single-line subject, no body. Let the diff speak.
- Plans, all interactions – concise. End plans with unresolved questions, if any.

## Code

- Clean, minimal code. Readability > cleverness.
- No over-engineering: no unnecessary abstractions, error handling, or features beyond what's asked. During planning, challenge each addition: does the caller already have this info?
- Small-lift additions within the active task's domain (completions, aliases, etc.) – just include them. Don't leave obvious follow-ups for the user to ask about.
- No adding comments/docstrings to untouched code.
- If a README exists and changes affect it, update it automatically.
- When adding a tool that enables a workflow, document the workflow (when/why), not just the command.
- After renames/refactors, grep for old name to catch stale references. Before broad find-replace, verify all match sites – short tokens hit unintended locations.
- Before proposing new tools/aliases, grep existing config to avoid duplicating what's already there.
- Verify platform capabilities before designing around them – don't assume features exist at system boundaries.
- Shell scripts (dotfiles): verify BSD (macOS) vs GNU flag compatibility.
- Flag performance when it matters – hot paths, large datasets, repeated calls. Don't optimize prematurely.
- Shell startup (.zshrc, etc.): never source commands that hit the network. Auth/token refreshes → on-demand or lazy.
- Go: default to unexported (lowercase). Only export when cross-package usage is confirmed.

## Agent

- Prefer speed/autonomy when working from agreed plan
- Log actions for visibility
- CLI tools (`gt`, `bzl`, etc.): always pass `--no-interactive` or equivalent. Never let a CLI block on stdin.
- Hang detection: run potentially-slow commands in background. Poll output – if no new output for 15s (with verbose/debug flags) or 30s (without), assume hung. Kill, retry with timeout, or fall back.
- Exit loops if no progress toward verifiable goal. Never loop 3+ times on same failure – stop, note pattern, ask.
- Ask before guessing paths/values – don't assume from directory listings.
- Flag over/under-prompting: if user is over-specifying something obvious, say so. If under-specifying is causing rework, flag that too.
- When working across repos, confirm target repo early.
- After disruptions (tool rejection, context restore, mode switch), verify actual state (git status, git diff, ls) before retrying.
- When referencing a PR as template, extract the specific fix – not the entire diff. PRs often bundle unrelated changes.

## Modes

- `teach me [topic]` → Socratic method. Calibrate level first, then make me reason. One concept per turn – no batching. No answer leakage. Code: anchor to source (`file_path:line_number`). Bridge from familiar languages (Go, TS).
- `eli5 [topic]` → Simplest first, I'll ask deeper.
- Plan mode is for code exploration + writing a plan. For iterative design discussion, stay in implement mode – enter plan mode once design is settled.
- Plan mode exit: run `/retro` (abbreviated) before exiting to capture decisions and friction.

## Workflow

Branch naming: `<type>/<slug>` (e.g. `feat/add-grep-tool`). All changes to main require a PR.
Checkpoint is the only release path – route through /checkpoint skill. After completing a task or set of changes, offer to checkpoint automatically. Never offer bare commit+push.

### Splitting changes
Prefer splitting logically independent changes (refactor, bug fix, feature) into stacked PRs.
Stacked PRs use Graphite (`gt`), not raw git:
- `gt create <branch>` not `git checkout -b` – creates branch and tracks stack
- `gt submit` (`gtsub`) not `git push` + `gh pr create` – creates/updates PRs for entire stack
- `gt restack` (`gtr`) not `git rebase` – rebases stack after changes
- `gt sync` not `git fetch` – pulls latest main into Graphite tracking
- `gt log short --stack` (`gts`) – view current stack

**Proactive (preferred):** When I recognize a separable change while working, branch + commit it immediately before continuing.

**Retroactive (at checkpoint):** If changes are already mixed, attempt to untangle. If too intertwined, ship as one PR and flag it.

Stack order: foundational changes first. Dependent features stack on top. Each PR targets the branch below it (or main for first).

### Retro
Auto-trigger – don't wait to be asked:
- `/retro` is context-aware: full at checkpoint/session end, abbreviated before context loss.
- Run automatically at checkpoint, session end, and before any context-loss event.

Context-loss triggers (always run `/retro` before these):
- Exiting plan mode / clearing context
- Switching repos/tasks
- Long break (user says "pause", "stop", "done for now")

## Stack

Primary: Go, TypeScript. Bazel build. Kubernetes, OpenAPI, gRPC.
Use as reference frame – draw analogies to these when explaining new tech or making design decisions.

## Testing

- TDD for core logic – write tests first, use as guardrails for autonomous work
- Table-driven tests (Go). Bazel: scope to affected targets
- No heavy mocks. If it needs mocks, rethink the boundary
- Integration tests: opt-in. Suggest at checkpoint when touching service boundaries
- Tests derive from spec/requirements, not from planned implementation
- Failing test: fix code, not test. Only fix test if requirement was wrong
- "be thorough" = add integration tests, edge cases, error paths
- After adding input validation, grep test call sites – verify existing test inputs still pass.

## Safety

In all modes:
- Never `rm -rf` outside of build/temp dirs. Always scoped, never `~/` or `/`.
- Never `git push --force` to main/master.
- Never `git reset --hard` or `checkout .` with uncommitted work; stash first.
- Never delete branches without confirming they're merged.
- Flag sensitive values (API keys, tokens) in files before committing/pushing – even if user is driving.
- Before creating repos in an org, verify permissions and constraints (branch protection, deletion, visibility).

## Git

- Conventional commits: feat:, fix:, chore:, refactor:, docs:, test:.
- Always run relevant tests before committing.
- GitHub CLI for all GitHub interactions.
- Always rebase, never merge – clean linear history. Branch from `origin/main`, not local main.
- Squash-merge PRs – one commit per PR on main.
- New repos → always `.gitignore` with `.DS_Store` immediately.
- In implement mode: never commit without user confirmation – show diff, summarize, wait for go-ahead.
- Before committing, verify current branch matches intent – check for open PRs and whether changes belong there.
- Feature branches: prefer rewriting history (reset + force push) over revert commits. Reverts only on main/shared branches.
- Never `git reset --soft main` – local main drifts. Use `HEAD~N` (relative) for squashing branch commits.
- Don't auto-squash branch commits at checkpoint – distinct logical commits (move, fix, feature) tell a story. Ask first.
- Git hygiene aliases (`dotfiles/shell/zshrc`): `gm` (main + pull + full cleanup), `gsync` (rebase onto main), `gclean` (cleanup only). Self-healing fetch auto-recovers stale refs. For Graphite stacks, use `gtr` not `gsync`.
- Hygiene aliases are safe anytime. Push operations (`gpush`, `gpushup`) only through /checkpoint.

## Pull Requests

- Title: conventional commit format, under 70 chars
- Title: describe the capability/behavior change, not the file diff
- Body: lead with why and what it enables. Explain the design/system – not line-by-line diff tables
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
- Descriptions = current intent, not changelog. No "what changed from v1" sections. Commit history handles evolution.
- Before `gh pr edit --body`: always `gh pr view --json body` first, merge with existing content. GitHub has no edit history; overwriting destroys user content permanently.
- Per-repo CLAUDE.md can override this template

## Memory

Model: session → INBOX.md (short-term) → triage → AGENTS.md (long-term)

- AGENTS.md = long-term memory. Cross-tool, synced via dotfiles. Only triage writes here.
- INBOX.md (`~/.agents/INBOX.md`) = short-term capture. Local, never synced.
- retro = capture process → INBOX.md. triage = promotion → AGENTS.md or discard.
- Triage when INBOX.md exceeds ~10 items. Proactively check and suggest `/triage` when it's growing – don't wait to be asked.
- Skills (shared workflows) live in `~/.agents/skills/` – both Claude Code and Cursor read from here.

Capture triggers:
- `log` / `idea: <thought>` → append to INBOX.md (date, context, idea)
- `win: <description>` → `~/.agents/wins.md` (promo-packet worthy)

When capturing friction:
- Self-resolve once. If reusable insight, suggest INBOX.md entry.
- At capture time, note if INBOX.md is growing and nudge toward triage.
