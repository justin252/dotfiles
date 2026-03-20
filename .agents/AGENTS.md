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
- Shell scripts: MUST read `.agents/conventions/shell-scripts.md` before writing or modifying shell scripts. Covers strict mode, quoting, cross-platform traps (BSD vs GNU), error handling, security, testing.
- Batch file processors: rescue/catch per item, not per batch. One bad file must not crash the tool.
- Don't embed volatile counts (test count, line count, file count) in docs or README. Describe what, not how many.
- When implementing from plan, challenge correctness of stateful operations (counters, file naming, sequencing). Plans are proposals, not specs.
- Platform-specific commands (`open`, `pbcopy`, `stat -f`, `date -j`): grep before shipping shell scripts. Guard with `command -v`.
- Flag performance when it matters – hot paths, large datasets, repeated calls. Don't optimize prematurely.
- Go: default to unexported (lowercase). Only export when cross-package usage is confirmed.
- CLI tools: MUST read `.agents/conventions/cli-guidelines.md` before writing code. clig.dev is a menu, not a checklist – apply recommendations to the tool's actual use case:
  - `--help`: universal. Every user-facing tool. Internal helpers get header comments instead.
  - `--json`: only where scripting/composability is real (orchestrators, status commands). Not for interactive fzf browsers.
  - `--quiet`, `--no-color`: only if the tool is used in automation/CI. Interactive-only tools skip these.
  - `--dry-run`: only for destructive operations on shared state.
  - Error messages: say what went wrong AND suggest a fix.
  - Always: stderr for messages, stdout for data. Exit 0/non-zero. Flags over positional args.
- New tools must follow the skeleton in `conventions/cli-guidelines.md § Tool Skeleton`. Reference impl: `tools/dotfiles`.
- CLI tool layering: lower layers never call higher layers. Each independently useful (e.g. `wt` never calls `ag`; `ag` composes `wt`).

## Agent

- Prefer speed/autonomy when working from agreed plan
- Log actions for visibility
- CLI tools (`gt`, `bzl`, etc.): always pass `--no-interactive` or equivalent. Never let a CLI block on stdin.
- Hang detection: run potentially-slow commands in background. Poll output – if no new output for 15s (with verbose/debug flags) or 30s (without), assume hung. Kill, retry with timeout, or fall back.
- Exit loops if no progress toward verifiable goal. Never loop 3+ times on same failure – stop, note pattern, ask.
- Ask before guessing paths/values – don't assume from directory listings.
- Saved artifacts (drafts, research, proposals) → `~/.agents/artifacts/<topic-folder>/` with descriptive slug filenames. Not `~/.cursor/plans/`. Mature designs can graduate to `.agents/docs/` (repo-synced).
- Before creating files/dirs, confirm destination with user – especially when "save locally" or "keep it local" is ambiguous between repo, dotfiles, and `~/.agents/artifacts/`.
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
- Subagent constraints: test-only runs – say "Do NOT modify any source files" (build-fix agents revert otherwise). Research runs – return findings in response, don't create files unless requested. Implement runs – edit files only, never commit.
- When plan references another PR/branch, diff its changes against current branch before shipping.
- Permission denial in autonomous mode: don't retry the same operation. Identify what was blocked, explain what permission it needs, and offer the manual command or suggest user run it interactively. Continue with remaining work that doesn't require the blocked permission.
- Autonomous session end: summarize completed work + remaining items. Send terminal notification so user knows the run finished.
- Background agents (`AG_BACKGROUND=1`): never block on clarification. If stuck after 3 turns with no progress, write `~/.agents/artifacts/<topic>/stuck.md` (what's blocked, what was tried) and exit.
- After design decisions that rename or remove concepts, grep all docs for the old concept before considering it done.
- Start minimal, add when needed. Don't design for consumers that don't exist yet.
- When designing skill boundaries, ask user to describe the full workflow before splitting responsibilities.
- Renames: confirm final name before editing files. Name churn with partial edits costs O(files × renames).
- Cross-repo tasks: create branches in all target repos before making any edits.
- At checkpoint, challenge whether TDD scaffolding (greps, pattern checks) should ship as permanent tests.
- When work spans repos, write session note with exact change specs for the second repo before ending.

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
- Plan mode pacing: let user drive. Present analysis, wait. Don't rush to structured questions or formalize into plan files before alignment.
- Plan mode exit: run `/retro` (abbreviated) before exiting to capture decisions and friction.

## Workflow

Branch naming: `<type>/<slug>` (e.g. `feat/add-grep-tool`). All changes to main require a PR.
Checkpoint is the only release path – route through /checkpoint skill. After completing a task or set of changes, always run /checkpoint. Never bare commit+push.

### Pipeline (The Circus)

Animal = identity + memory. Skill = behavior. Each stage self-reflects via epilogue, then hands off. Artifacts are the interfaces.

```
🐙 design (/propose)    → plan.md
🦫 branch (/tidy)       → healthy stack
🐕 implement (/execute) → code + tests
🦅 ship (/checkpoint)   → PR, output.md
🦉 review (/review)     → review.md
🦁 dispatch (/lion)     → orchestrates pipeline
🐘 curator (/triage)    → graduates learnings across all animals
```

Each independently useful. `ag run <topic>` composes them into a pipeline. Learning is continuous – every animal captures; elephant curates.

Full spec (model selection, learning model, build order): `~/.agents/docs/circus.md`

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
- `bash -n` is syntax only; mentally trace execution context, platform, and edge cases before shipping.
- TDD greps/pattern checks are scaffolding; ship behavioral tests that verify output, not source patterns.
- If a test needs a workaround to pass, fix the code under test, not the test.

## Safety

In all modes:
- Never `rm -rf` outside of build/temp dirs. Always scoped, never `~/` or `/`.
- Never `git push --force` to main/master.
- Never `git reset --hard` or `checkout .` with uncommitted work; stash first.
- Never delete branches without confirming they're merged.
- Flag sensitive values (API keys, tokens) in files before committing/pushing – even if user is driving.
- Before creating repos in an org, verify permissions and constraints (branch protection, deletion, visibility).
- Public repos: never reference employer, internal tools, or "leaking" in commits, PRs, or comments. Use neutral language.

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
- `gh` commands must run from the target repo's cwd. `--repo` flag alone is not enough; `git -C` works for git but not gh.
- After `git mv`, `git add` both old and new paths to ensure rename detection.
- Nested rebase conflicts: `git show <branch>:<file>` to get final intended content from the branch tip. Works when rebasing onto a new base with same content.
- "Verify platform capabilities" means try the command or read source, not just check `--help`. Tools with plumbing/porcelain split hide commands from help text.

## Pull Requests

- Title: conventional commit format, under 70 chars
- Title: describe the capability/behavior change, not the file diff
- PRs are accomplishment records – what the system can now do, not a line-by-line diff of file changes
- Use visuals: tables (before/after, feature matrix), command examples, ASCII diagrams to show system state
- Body structure:
  ```
  ## Motivation
  <why this change – the problem or need, link to issue if applicable>

  ## What this does
  <capabilities enabled, workflows changed – the "so what">
  <tables, before/after, command examples, diagrams where helpful>

  ## Design decisions
  <key choices, tradeoffs, gotchas – skip for trivial PRs>

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
- Skills (shared workflows) live in `~/.agents/skills/` – both Claude Code and Cursor read from here. Skill frontmatter must include `name` + `description` at minimum (Codex enforces).
- Skill vs instruction: single command + context → AGENTS.md instruction. Multi-step, branching logic, or cross-repo → skill.
- When updating a skill or its reference example, diff conventions against the artifact to catch drift.

Artifacts (local, working):
- `~/.agents/artifacts/<topic>/` = all long-lived artifacts. Flat by topic, frontmatter for metadata. Local-only (`.gitignore`).
- Core artifacts: problem.md (why), design.md (how), plan.md (what/when), reference.md (learnings).
- Delivery artifacts: output.md (what shipped), review.md (review loop for an output). Multi-output topics can use `outputs/<slug>.md` and `reviews/<slug>.md`.
- Pipeline: problem → design → plan → output → review → checkpoint. Each artifact type except reference can use ## Open for feedback loop.
- Skills that produce structured findings (review, retro, triage) always persist artifacts. Chat/terminal output is supplementary, never the primary record. On write failure, warn and continue.
- Templates: `~/.agents/conventions/artifact-templates.md`. Agents consult when creating artifacts.
- `load <topic>` → search `~/.agents/artifacts/`, `~/.agents/docs/`, and `~/.agents/sessions/`. Partial match; ambiguous → show options. Read all artifact types, summarize status + next steps.
- `~/.agents/conventions/workflow.md` – comprehensive workflow reference. Read on demand: `@~/.agents/conventions/workflow.md`.

Docs (persisted, synced):
- `~/.agents/docs/<slug>.md` = persisted reference docs. Synced via dotfiles repo (`.agents/docs/`).
- Mature artifacts (designs, system descriptions) graduate here when they should survive across machines.
- Updated by human or at checkpoint when design evolves significantly.

Composability:
- Pipeline: /propose persists to artifacts/, /execute tracks progress in plan.md, outputs carry concrete delivery state, /checkpoint ships and can trigger review. Mature artifacts graduate to docs/ at checkpoint.
- Transitions + skill→doc mapping: see `~/.agents/conventions/workflow.md` § Composability.

Capture:
- `log <thought>` → agent appends to INBOX.md (date, context, idea). Not a shell alias – agent writes via bash.
- `win: <description>` → agent appends to `~/.agents/wins.md` (promo-packet worthy).
- Self-resolve friction once. If reusable, suggest INBOX.md entry.
- At capture time, note if INBOX.md is growing and nudge toward triage.

## Dotfiles

Personal dotfiles repo (`justin252/dotfiles`): universal base layer. A separate work dotfiles repo can overlay on top (shell, agent rules, skills) via its own `install.sh`. Overlays are optional; this repo works standalone.

- `~/.zprofile` is machine-local (tool installers like brew, pipx, volta own it). Dotfiles manage zshrc, not zprofile.

### Shell config layering

```
~/.zshrc              -> ~/dotfiles/shell/zshrc         (universal, synced)
  sources ~/.zshrc.work       (work overlay, if present)
  sources ~/.zshrc.personal   (personal overlay, if present)
```

Overlays are symlinked by their respective install scripts. Personal zshrc ends with `true` to avoid exit-code leaks from conditional last lines.

### install.sh

Idempotent. Safe to re-run anytime. What it does:
- Symlinks: `~/.zshrc`, `~/tools`, `~/.agents/AGENTS.md`, `~/.agents/skills/*/`, `~/.agents/conventions/`, `~/.agents/docs/`, `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `~/.claude/agents/`
- Copies skills to `~/.cursor/skills/` (Cursor doesn't follow symlinks)
- Seeds local-only files: `~/.agents/INBOX.md`, `~/.agents/wins.md`, `~/.agents/artifacts/`
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

Cursor skills: copied (not symlinked) because Cursor doesn't follow symlinks for skill discovery (known bug). Run `dot` to rebuild skills (it refreshes automatically). `dot` rebuilds `~/.agents/skills` from dotfiles sources, then re-syncs Claude/Cursor from that shared layer.

### Key tools

All on PATH via `~/tools` symlink:
- `h` – fzf alias browser. `h suggest` surfaces forgotten aliases from history.
- `dotfiles` – unified dotfiles sync: pull repos, verify/repair symlinks, refresh skills, sync configs, re-source shell. `dotfiles setup` for full rebuild. `dotfiles doctor` for read-only diagnostics.
- `sz` – re-source zshrc after edits
- `rebase-wip` – stash local edits, fetch/rebase onto a target branch, then reapply the stash. Useful when dotfiles change mid-task
- `ag` – agent session manager (stage 6-7 orchestrator). One command for parallel work: `ag <name>` auto-creates worktree + launches agent. `ag <name> -m MSG` with initial task (background launch; prints guided output, doesn't attach). `ag` fzf dashboard (all repos). `ag status` cross-repo view. `ag kill <name>` kill session. `ag clean` dead sessions + merged worktrees (`--force` skips prompt, `--all` nuclear reset). Name flows everywhere: branch, session, worktree, tmux status bar. Tmux status shows `name●` (active) / `name○` (idle). `C-a a` for popup dashboard.
- `wt` – navigate to any branch or PR. `wt <branch>` finds existing worktree or creates one. `wt 90` or `wt <PR-URL>` resolves PR. `wt` fzf switch. `wt -d` delete. `wt list` show all. `wt clean` remove merged worktrees. `wt clean --all` remove all worktrees. Composable: `ag` delegates worktree ops here.
- `wss` – workspace SSH+tmux. `wss <name>` connect, `wss` fzf picker. Work-only (macOS guard).
- `artifacts` (`a`) – unified artifact browser (fzf). Sources: `~/.agents/artifacts/`. Frontmatter-aware picker: [type] topic repo/component status. Actions: edit, view, execute, propose, review, claude, cursor. `artifacts <query>` pre-filters.
- `review` – Codex code review for any PR or branch. `review` (auto-detect), `review 123` (PR), `review --status` (check progress), `review --json` (machine output). Always async; writes `review.md` + `review-state.json` to auto-discovered topic dir, notifies on completion.
- `session` (`s`) – session notes browser (fzf). Sources: `~/.agents/sessions/`. Curated .md summaries for context handoff to new sessions. `session <query>` pre-filters.
- `t` – tools browser (fzf). Discovers all tools in `~/tools/`, grouped by `# category:` comment. Preview pane shows `--help`. `t <query>` pre-filters.

### Reference library

On-demand context. Read when triggered; never auto-load.

Docs (`~/.agents/docs/`):
- `circus.md` – agent pipeline architecture, model selection, build order. Read when working on ag, skills, orchestration, or pipeline design.

Conventions (`~/.agents/conventions/`):
- `shell-scripts.md` – strict mode, quoting, BSD/GNU traps. MUST read before writing shell scripts.
- `cli-guidelines.md` – clig.dev applied. MUST read before writing CLI tools.
- `skill-guidelines.md` – skill structure, frontmatter, testing. Read before writing or modifying skills.
- `artifact-templates.md` – artifact frontmatter, templates. Consult when creating artifacts.
- `workflow.md` – full workflow reference, skill composability. Read on demand.

AGENTS-work.md extends this library with work-specific entries.

### Testing dotfiles changes

```bash
# Sandbox test (isolated HOME, stubs, behavioral)
bash ~/dotfiles/tests/sandbox.sh

# Quick checks (no sandbox needed)
zsh -n <file>                               # syntax check
zsh -c 'source ~/.zshrc; source ~/.zshrc'   # double-source
```
