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
- After renames/refactors, grep the entire repo for old name to catch stale references (including docs, help text, inline strings – not just code). Before broad find-replace, verify all match sites – short tokens hit unintended locations.
- After merging/deduplicating lists, verify each exact item – don't summarize as families or wildcards.
- Before proposing new tools/aliases, grep existing config to avoid duplicating what's already there.
- Verify platform capabilities before designing around them – don't assume features exist at system boundaries.
- Shell scripts (dotfiles): verify BSD (macOS) vs GNU flag compatibility. Dotfiles run on both macOS (laptop) and Linux (workspace); prefer cross-platform implementations, only guard with `$OSTYPE` when genuinely platform-specific (desktop apps, macOS-only tools). Use existence checks (`command -v`, `[[ -d ]]`) over OS checks when possible.
- Dotfiles install/repair flows: design for a clean machine first. Create dirs before scanning them; keep optional integrations non-fatal; only remove clearly managed paths; smoke-test with a temp `HOME`.
- Flag performance when it matters – hot paths, large datasets, repeated calls. Don't optimize prematurely.
- Shell startup (.zshrc, etc.): never source commands that hit the network. Auth/token refreshes → on-demand or lazy.
- Go: default to unexported (lowercase). Only export when cross-package usage is confirmed.
- CLI tools: when building or improving a CLI, MUST read `.agents/references/cli-guidelines.md` before writing code (distilled from https://clig.dev/). Key defaults: flags over positional args, `--json`/`--quiet`/`--no-color`, stderr for messages, TTY detection, confirm before destructive ops, exit 0/non-zero.

## Agent

- Prefer speed/autonomy when working from agreed plan
- Log actions for visibility
- CLI tools (`gt`, `bzl`, etc.): always pass `--no-interactive` or equivalent. Never let a CLI block on stdin.
- Hang detection: run potentially-slow commands in background. Poll output – if no new output for 15s (with verbose/debug flags) or 30s (without), assume hung. Kill, retry with timeout, or fall back.
- Exit loops if no progress toward verifiable goal. Never loop 3+ times on same failure – stop, note pattern, ask.
- Ask before guessing paths/values – don't assume from directory listings.
- Saved docs (drafts, research, proposals) → `~/.agents/docs/<topic-folder>/` with descriptive slug filenames. Not repo `docs/`, not `~/.cursor/plans/`. Exception: project design docs that belong with the repo stay in-repo (e.g. `docs/design/`).
- Before creating files/dirs, confirm destination with user – especially when "save locally" or "keep it local" is ambiguous between repo, dotfiles, and `~/.agents/docs/`.
- Flag over/under-prompting: if user is over-specifying something obvious, say so. If under-specifying is causing rework, flag that too. When flagging, log the pattern to INBOX.md so /triage can promote it to a default (AGENTS.md rule, alias, or skill).
- For review/planning sessions, present 1–2 decisions at a time, not a full menu.
- When working across repos, confirm target repo early.
- After disruptions (tool rejection, context restore, mode switch, concurrent edits from another tool), verify actual state (git status, git diff, ls) before retrying.
- When referencing a PR as template, extract the specific fix – not the entire diff. PRs often bundle unrelated changes.
- When source-of-truth artifacts change significantly, rebuild downstream from the new truth. Don't patch old artifacts around updated ones.
- Before entering plan mode on a branch with uncommitted changes, check `git diff --stat` – the plan may already be implemented.
- Before adding files/config to a codebase path, verify the path is stable – check for pending migrations or renames that would move the target.
- In worktrees: verify edit target matches the worktree. `ag` worktree sessions should edit within the worktree, not the main repo checkout.
- Multi-file tasks (3+ files, distinct context per step): delegate each logical step to a Task subagent with focused context. Inline is fine for <3 files or heavily shared context.
- Test-only subagent runs: explicitly say "Do NOT modify any source files." Build-fix agents will otherwise revert your changes to satisfy the compiler.
- Permission denial in autonomous mode: don't retry the same operation. Identify what was blocked, explain what permission it needs, and offer the manual command or suggest user run it interactively. Continue with remaining work that doesn't require the blocked permission.
- Autonomous session end: summarize completed work + remaining items. Send terminal notification so user knows the run finished.

### Interruption routing

When a side idea or tangent surfaces mid-task, route by blast radius:

- **Trivial** (typo fix, alias addition, small refactor in current file): do it inline, now
- **Low** (self-contained task, different file/module): delegate to a subagent, continue main work
- **Medium** (new feature, cross-cutting change, needs its own branch): log to INBOX.md, finish current task first
- **High** (new system, architectural change, multi-session effort): log to INBOX.md with enough context to /propose later. Never start mid-session.

Default to higher blast radius when uncertain. The cost of context-switching is almost always higher than the cost of deferring.

## Modes

- `teach me [topic]` → Socratic method. Calibrate level first, then make me reason. One concept per turn – no batching. No answer leakage. Code: anchor to source (`file_path:line_number`). Bridge from familiar languages (Go, TS).
- `eli5 [topic]` → Simplest first, I'll ask deeper.
- `teach` (during execute) → Narrate changes. How each diff fits plan, gotchas, idioms. Link code inline. Approve each logical unit.
- `poc <idea>` → Prove it works. Feasibility research → minimal build → draft PR with gaps documented. Single branch, no stacking. Requires `ccy`.
- Plan mode is for code exploration + writing a plan. For iterative design discussion, stay in execute mode – enter plan mode once design is settled. Exception: plan mode suits exploratory design in a new domain where read-only codebase scanning drives the discussion.
- Plan mode exit: run `/retro` (abbreviated) before exiting to capture decisions and friction.

## Workflow

Branch naming: `<type>/<slug>` (e.g. `feat/add-grep-tool`). All changes to main require a PR.
Checkpoint is the only release path – route through /checkpoint skill. After completing a task or set of changes, offer to checkpoint automatically. Never offer bare commit+push.

### Splitting changes
Prefer splitting logically independent changes (refactor, bug fix, feature) into stacked PRs.
Stacked PRs use Graphite (`gt`), not raw git:
- `gt create <branch>` not `git checkout -b` – creates branch and tracks stack
- `gt submit --draft` (`gtsub`) not `git push` + `gh pr create` – creates/updates PRs for entire stack. Always `--draft`; never `--publish` (means "not draft")
- `gt restack` (`gtr`) not `git rebase` – rebases stack after changes
- `gt sync` not `git fetch` – pulls latest main into Graphite tracking
- `gt log short --stack` (`gts`) – view current stack
- Graphite fallback: if `gt submit` fails (permissions, trunk behind), don't debug – fall back to `git push -u origin <branch>` + `gh pr create --draft`

**Proactive (preferred):** When I recognize a separable change while working, branch + commit it immediately before continuing.

**Retroactive (at checkpoint):** If changes are already mixed, attempt to untangle. If too intertwined, ship as one PR and flag it.

Stack order: foundational changes first. Renames/refactors go in the first PR – never mid-stack (causes conflict cascades on every downstream branch). Dependent features stack on top. Each PR targets the branch below it (or main for first).
Each stacked PR must be independently correct at its point in the stack – if a fix belongs in an earlier PR, amend there and restack rather than patching at the tip.
Rebasing stacked PRs: rebase each branch onto its parent PR branch, not main, until the parent merges. Use `git rebase --onto <target> <old-base>` to isolate just the branch's own commits.

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
- At review-to-execute transitions, re-read Testing section – analysis mindset skips TDD.

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
- `gh pr create` always uses `--draft` unless repo-level AGENTS.md says otherwise. In worktrees, always pass `--head <branch>` (gh can't detect tracking branch).
- New repos → always `.gitignore` with `.DS_Store` immediately.
- In execute mode: never commit without user confirmation – show diff, summarize, wait for go-ahead.
- Before committing, verify current branch matches intent – check for open PRs, whether the PR is already merged, and whether changes belong there.
- Feature branches: prefer rewriting history (reset + force push) over revert commits. Reverts only on main/shared branches.
- Never `git reset --soft main` – local main drifts. Use `HEAD~N` (relative) for squashing branch commits.
- Don't auto-squash branch commits at checkpoint – distinct logical commits (move, fix, feature) tell a story. Ask first.
- Git hygiene aliases (`dotfiles/shell/zshrc`): `gm` (main + pull + full cleanup), `gsync` (rebase onto main), `gclean` (cleanup only). Self-healing fetch auto-recovers stale refs. For Graphite stacks, use `gtr` not `gsync`.
- Hygiene aliases are safe anytime. Push operations (`gpush`, `gpushup`) only through /checkpoint.
- Don't stash across branches when files differ. Make changes directly on target branch, or cherry-pick.
- `--force-with-lease` fails after amend/rebase (tracking ref stale even after fetch). On personal feature branches, use `--force`. Alternative: `git push --force-with-lease=<branch>:<old-sha>` with SHA from `FETCH_HEAD`.

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
- Before `gh pr edit --body`: always `gh pr view --json body` first, diff new content against existing, merge. GitHub has no edit history; overwriting destroys user content permanently.
- Per-repo CLAUDE.md can override this template

## Memory

Model: session → INBOX.md (short-term) → triage → AGENTS.md (long-term)

- AGENTS.md = long-term memory. Cross-tool, synced via dotfiles. Only triage writes here.
- INBOX.md (`~/.agents/INBOX.md`) = short-term capture. Local, never synced.
- retro = capture process → INBOX.md. triage = promotion → AGENTS.md or discard.
- Triage when INBOX.md exceeds ~10 items. Proactively check and suggest `/triage` when it's growing – don't wait to be asked.
- Skills (shared workflows) live in `~/.agents/skills/` – both Claude Code and Cursor read from here.
- Skill vs instruction: single command + context → AGENTS.md instruction. Multi-step, branching logic, or cross-repo → skill.
- When updating a skill or its reference example, diff conventions against the artifact to catch drift.

Docs:
- `~/.agents/docs/<topic>/` = all long-lived docs. Flat by topic, frontmatter for metadata. Local-only (`.gitignore`).
- Core docs: problem.md (why), design.md (how), plan.md (what/when), reference.md (learnings).
- Delivery artifacts: output.md (what shipped), review.md (review loop for an output). Multi-output topics can use `outputs/<slug>.md` and `reviews/<slug>.md`.
- Pipeline: problem → design → plan → output → review → checkpoint. Each doc type except reference can use ## Open for feedback loop.
- Templates: `~/.agents/references/doc-templates.md`. Agents consult when creating docs.
- `load <topic>` → search `~/.agents/docs/` and `~/.agents/sessions/`. Partial match; ambiguous → show options. Read all doc types, summarize status + next steps.
- `~/.agents/references/workflow.md` – comprehensive workflow reference. Read on demand: `@~/.agents/references/workflow.md`.

Composability:
- Pipeline: /propose persists to docs/, /execute tracks progress in plan.md, outputs carry concrete delivery state, /checkpoint ships and can trigger review.
- Transitions + skill→doc mapping: see `~/.agents/references/workflow.md` § Composability.

Capture:
- `log` / `idea: <thought>` → append to INBOX.md (date, context, idea)
- `win: <description>` → `~/.agents/wins.md` (promo-packet worthy)
- Self-resolve friction once. If reusable, suggest INBOX.md entry.
- At capture time, note if INBOX.md is growing and nudge toward triage.

## Dotfiles

Personal dotfiles repo (`justin252/dotfiles`): universal base layer. A separate work dotfiles repo can overlay on top (shell, agent rules, skills) via its own `install.sh`. Overlays are optional; this repo works standalone.

### Shell config layering

```
~/.zshrc              -> ~/dotfiles/shell/zshrc         (universal, synced)
  sources ~/.zshrc.work       (work overlay, if present)
  sources ~/.zshrc.personal   (personal overlay, if present)
```

Overlays are symlinked by their respective install scripts. Personal zshrc ends with `true` to avoid exit-code leaks from conditional last lines.

### install.sh

Idempotent. Safe to re-run anytime. What it does:
- Symlinks: `~/.zshrc`, `~/tools`, `~/.agents/AGENTS.md`, `~/.agents/skills/*/`, `~/.agents/references/`, `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.claude/agents/`
- Copies skills to `~/.cursor/skills/` (Cursor doesn't follow symlinks)
- Seeds local-only files: `~/.agents/INBOX.md`, `~/.agents/wins.md`, `~/.agents/docs/`
- Installs fzf if missing (brew on macOS, binary download on Linux)
- Sets `git pull.rebase true`
- Karabiner: copies (not symlinks) on macOS

Contribution defaults:
- Clean-machine-first: `mkdir -p` before `find`/loops over managed dirs
- Optional integrations warn instead of aborting the full install
- Only delete clearly managed paths; if a path might contain user content, prefer symlink-only removal or warn
- Validate on both macOS/BSD and Linux/GNU shell behavior

### Agent config distribution

```
~/.agents/AGENTS.md          <- source of truth (this file)
  Claude Code                @import via CLAUDE.md (native)
  Cursor                     paste into User Rules (Settings > Rules)

~/.agents/AGENTS-work.md     <- work overlay (if present)
  Claude Code                @import via CLAUDE.md (native)
  Cursor                     paste into User Rules alongside AGENTS.md

~/.agents/skills/            <- merged personal + work skills
  Claude Code                symlinks from ~/.claude/skills/
  Cursor                     copied to ~/.cursor/skills/
  Codex CLI                  reads ~/.agents/skills/ directly in this setup

Repo-root AGENTS.md          <- per-project, auto-discovered by both tools
```

Cursor does NOT follow @import or read `~/.agents/` directly. User Rules (plain text in Settings UI) is the only global mechanism; no file-based auto-load. Paste both AGENTS.md and AGENTS-work.md into User Rules for full context.

Cursor skills: copied (not symlinked) because Cursor doesn't follow symlinks for skill discovery (known bug). Run `refresh-skills` after editing skills, or `pull-dot` (which calls it automatically). `refresh-skills` rebuilds `~/.agents/skills` from dotfiles sources first, then re-syncs Claude/Cursor from that shared layer.

### Key tools

All on PATH via `~/tools` symlink:
- `h` – fzf alias browser. `h suggest` surfaces forgotten aliases from history.
- `pull-dot` – pull dotfiles + re-source zshrc (work version pulls both repos + refreshes shared skills + Codex defaults)
- `reset-dot` – rebuild dotfiles-managed symlinks/copies/config scaffolding, then re-source zshrc. Preserve local-only state
- `refresh-skills` – rebuild `~/.agents/skills` from dotfiles sources, then re-sync Claude skill symlinks and re-copy Cursor skills (run after editing skills)
- `sync-codex-config` – sync top-level Codex autonomy defaults without replacing auth/trust state or profile-specific settings
- `sz` – re-source zshrc after edits
- `rebase-wip` – stash local edits, fetch/rebase onto a target branch, then reapply the stash. Useful when dotfiles change mid-task
- `ag` – agent session manager (stage 6-7 orchestrator). One command for parallel work: `ag <name>` auto-creates worktree + launches agent. `ag <name> -m MSG` with initial task. `ag` fzf dashboard (all repos). `ag status` cross-repo view. `ag kill <name>` kill session. `ag clean` dead sessions + merged worktrees (`--force` skips prompt). Name flows everywhere: branch, session, worktree, tmux status bar. Tmux status shows `name●` (active) / `name○` (idle). `C-a a` for popup dashboard.
- `wt` – git worktree plumbing. `wt <name>` create, `wt` fzf switch, `wt -d` delete, `wt status`, `wt clean`. Mostly used through `ag`; direct use for worktree-only ops.
- `wss` – workspace SSH+tmux. `wss <name>` connect, `wss` fzf picker. Work-only (macOS guard).
- `doc` – unified doc browser (fzf). Sources: `~/.agents/docs/`. Frontmatter-aware picker: [type] topic repo/component status. Actions: edit, view, execute, propose, review, claude, cursor. `doc <query>` pre-filters.
- `review-output` – create/update the current topic output artifact and run Codex review into the linked review artifact
- `sesh` – session notes browser (fzf). Sources: `~/.agents/sessions/`. Curated .md summaries for context handoff to new sessions. `sesh <query>` pre-filters.

### Testing dotfiles changes

```bash
zsh -n <file>                                    # syntax check
zsh -c 'source ~/.zshrc && echo OK'              # clean source
bash ~/dotfiles/install.sh                       # idempotent re-run
zsh -c 'source ~/.zshrc; source ~/.zshrc'        # double-source (catches alias conflicts)
bash -c 'HOME="$(mktemp -d)" bash ~/dotfiles/install.sh'   # clean-machine smoke test
```
