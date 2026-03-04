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
- After renames/refactors, grep for old name to catch stale references.
- Shell scripts (dotfiles): verify BSD (macOS) vs GNU flag compatibility.
- Flag performance when it matters – hot paths, large datasets, repeated calls. Don't optimize prematurely.
- Go: default to unexported (lowercase). Only export when cross-package usage is confirmed.

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
- Before `gh pr edit --body`: always `gh pr view --json body` first, merge with existing content. GitHub has no edit history; overwriting destroys user content permanently.
- Per-repo CLAUDE.md can override this template

## Agent

- Prefer speed/autonomy when working from agreed plan
- Read-only ops (ls, web search, read queries) never need confirmation
- Avoid unnecessary bash: `echo`/`printf` for output (use direct text), interactive flags (`-i`), commands waiting on stdin – these hang on approval prompts.
- Log actions for visibility
- CLI tools (`gt`, `bzl`, etc.): always pass `--no-interactive` or equivalent. Never let a CLI block on stdin.
- Hang detection: run potentially-slow commands in background. Poll output – if no new output for 15s (with verbose/debug flags) or 30s (without), assume hung. Kill, retry with timeout, or fall back. Never sit idle waiting on a silent command.
- Exit loops if no progress toward verifiable goal
- Ask before guessing paths/values – don't assume from directory listings
- Before proposing new tools/aliases, grep existing config to avoid duplicating what's already there.
- Flag over/under-prompting: if user is over-specifying something obvious, say so. If under-specifying is causing rework, flag that too.
- Plan files: auto-generated plans stay in `~/.claude/plans/` (Claude Code manages). Saved plans promoted to `~/.claude/plans/saved/<slug>.md` via `save plan`. Header: `# Title` + `> Status: draft | active | done` + `> Repo: <repo> | Branch: <branch>`.
- Plan cleanup: delete saved plan after PR is merged. Until then, it's the working reference.
- Before broad find-replace, verify all match sites – short tokens hit unintended locations.
- When referencing a PR as template, extract the specific fix – not the entire diff. PRs often bundle unrelated changes.
- Scripts/tools go in `~/tools` (symlinked from dotfiles). INBOX.md is for ideas/friction – not finished artifacts.
- Slash command specs override CLAUDE.md constraints for their active scope (e.g. /yolo overrides "never commit without confirmation").
- When extracting CLAUDE.md specs to slash commands: keep behavioral constraints in CLAUDE.md, reduce to one-line pointer for procedural steps. Every extraction should ask: what implicit policy was the inline spec enforcing?
- When working across repos, confirm target repo early – cwd resets to primary working dir after each Bash command.
- Verify platform capabilities before designing around them – don't assume features exist at system boundaries.

## Modes

- `teach me [topic]` → Socratic method. Calibrate my level first, then make me reason. One concept per turn – no batching. No answer leakage in questions/suggestions. Code: full block → intent → component walkthrough. Show only relevant lines while teaching; full file as payoff at end.
  - Anchor all code references to source (`file_path:line_number`) – no detached snippets.
  - Bridge from familiar languages (Go, TS) – build cross-language intuition, not just translate syntax.
  - After plan approval, ask: drive (user codes), teach-while-coding (I implement + explain), or just implement.
- `eli5 [topic]` → Simplest first, I'll ask deeper.
- Plan mode is for code exploration + writing a plan. For iterative design discussion, stay in implement mode – enter plan mode once design is settled.

### Working posture
- **Plan** → Claude Code's built-in plan mode. Read-only, deliberate.
- **Implement** (default after plan approval) → Execute agreed plan. Handle errors autonomously (retry once, then flag). Pause at checkpoint: show diff, summarize, confirm before commit/push/PR.
- **Yolo** → `/yolo <plan ref>`. `<plan ref>` = saved plan slug (searched in `plans/saved/`), file path, or issue number. See `/yolo` command for full spec.

## Workflow

Branch naming: `<type>/<slug>` (e.g. `feat/add-grep-tool`). All changes to main require a PR – no exceptions, no direct pushes.
Checkpoint is the only release path. Never offer bare commit+push – always route through /checkpoint.

### Splitting changes
Prefer splitting logically independent changes (refactor, bug fix, feature) into stacked PRs.
Stacked PRs use Graphite (`gt`), not raw git:
- `gt create <branch>` not `git checkout -b` – creates branch and tracks stack
- `gt submit` (`gtsub`) not `git push` + `gh pr create` – creates/updates PRs for entire stack
- `gt restack` (`gtr`) not `git rebase` – rebases stack after changes
- `gt sync` not `git fetch` – pulls latest main into Graphite tracking
- `gt log short --stack` (`gts`) – view current stack

**Proactive (preferred):** When I recognize a separable change while working, branch + commit it immediately before continuing. Cleanest path.

**Retroactive (at checkpoint):** If changes are already mixed, attempt to untangle (split commits, cherry-pick, rebase). If changes are too intertwined to split cleanly, ship as one PR and flag it – don't butcher the split.

Stack order: foundational changes (refactors, extractions, fixes) go first. Dependent features stack on top. Each PR targets the branch below it (or main for first).

### `checkpoint`
Build, test, split/ship PRs, commit, push, win check, retro. Full spec: /checkpoint command.

### Retro
Two tiers:
- `retro` (full) → /retro command. At checkpoint or session end. Full session review.
- `retro:quick` → Before any context-loss event. Scan conversation for decisions, friction, wrong assumptions. Write quick INBOX.md entries. 30 seconds, not a full review.

Context-loss triggers (always run `retro:quick` before these):
- Entering plan mode
- Clearing context
- Switching repos/tasks
- Long break (user says "pause", "stop", "done for now")

## Meta

How learning works: I read CLAUDE.md at session start – no persistent memory beyond this file. All captures go to `~/.claude/INBOX.md` (local, never synced). Only `triage` promotes to CLAUDE.md.
Skills (shared workflows) live in `~/.claude/skills/` – both Claude Code and Cursor read from here.

When to capture:
- Context-loss event imminent? → `retro:quick`
- Mid-session friction, self-resolved? → suggest INBOX.md entry

When I hit friction:
- Self-resolve once. If reusable insight, suggest INBOX.md entry.
- Never loop 3+ times on same failure – stop, note pattern, ask.

Commands – artifacts (`verb type [slug]`, all under `~/.claude/`):

| Verb | plan | convo | doc |
|---|---|---|---|
| **save** | `save plan [slug]` | `save convo [slug]` | `save doc [slug]` |
| **list** | `list plans` | `list convos` | `list docs` |
| **load** | `load plan <slug>` | `load convo <slug>` | `load doc <slug>` |
| **new** | – (plan mode creates) | – | `new doc [slug]` |

- `save`: copies to respective bucket. Plans get status header; slug derived from title if omitted. Convos are incremental (appends).
- `list/load`: show slug – title. Load reads into context; partial prefix match, ambiguous → show options.
- `new doc [slug]`: create fresh doc in `~/.claude/docs/`.

Commands – capture (quick):
- `checkpoint` → /checkpoint command
- `retro` → /retro command (full, at checkpoint/session end)
- `retro:quick` → scan for decisions/friction, write INBOX.md entries (before context loss)
- `log` → idea/tangent → INBOX.md (date, context, idea, action)
- `idea: <thought>` → ideate, then log
- `win: <description>` → promo-packet worthy accomplishment → `~/.claude/wins.md`. Also auto-detected at checkpoint.
- `pick` → backlog item from INBOX.md. Present items, plan, execute after approval

Capture entries: `**Triage:** <type> → <destination>, <effort>` (e.g. `insight → CLAUDE.md Agent, quick`).

Triage when INBOX.md exceeds ~10 items. At capture time, note if growing and nudge.
- `triage` → /triage. Sort INBOX items (promote/discard/refine), execute by priority. Also review existing CLAUDE.md rules – for each, ask: when did this last prevent a mistake or change behavior? If never/can't remember, cut it.

## Setup

- `~/.claude/CLAUDE.md` → symlinked from `~/dotfiles/.claude/CLAUDE.md` – only edit the dotfiles copy
- `install.sh` creates symlinks; this is how the dotfiles repo works
- Karabiner: `install.sh` copies (not symlinks) `karabiner/karabiner.json` → `~/.config/karabiner/` because Karabiner overwrites symlinks. After editing the dotfiles copy, run `cp ~/dotfiles/karabiner/karabiner.json ~/.config/karabiner/karabiner.json` to sync live.
- `~/.claude/INBOX.md` – local capture scratchpad, never synced
- `~/.claude/plans/saved/` – saved plans (promoted from auto-generated `plans/`), never synced
- `~/.claude/sessions/` – saved conversation logs, never synced
- `~/.claude/docs/` – long-lived documents (RFCs, design docs, proposals), never synced
- Shell config layers: `dotfiles/shell/zshrc` (universal, synced) → `~/.zshrc.work` (work only) → `~/.zshrc.personal` (personal only). Machine-specific values go in local files.
- To detect context: check which local zshrc files exist on the machine.
- Personal tools: `~/tools` (symlinked from `~/dotfiles/tools/`, on PATH).
- `~/code` – project root for all repos.