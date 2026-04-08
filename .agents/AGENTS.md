## Style

- Extremely concise. Sacrifice grammar for concision.
- No em dashes (—). Use en dashes (–), semicolons, or restructure.
- Commit messages – single-line subject, no body. Let the diff speak.
- Plans, all interactions – concise. End plans with unresolved questions, if any.

## Code

- Clean, minimal code. Readability > cleverness.
- No over-engineering: no unnecessary abstractions, error handling, or features beyond what's asked. During planning, challenge each addition: does the caller already have this info?
- Small-lift additions within the active task's domain (completions, aliases, etc.) – just include them. Don't leave obvious follow-ups for the user to ask about.
- No adding comments/docstrings to untouched code. In code you write or modify, comment non-obvious patterns (the why, not the what).
- If a README exists and changes affect it, update it automatically.
- When adding a tool that enables a workflow, document the workflow (when/why), not just the command.
- After renames/refactors, grep the entire repo for old name to catch stale references (including docs, help text, inline strings – not just code). Before broad find-replace, verify all match sites – short tokens hit unintended locations.
- After merging/deduplicating lists, verify each exact item – don't summarize as families or wildcards.
- Before proposing new tools/aliases, grep existing config to avoid duplicating what's already there.
- Verify platform capabilities before designing around them. Try the command or read source, not just `--help` – plumbing/porcelain splits hide commands.
- Shell scripts: MUST read `.agents/conventions/shell-scripts.md` before writing or modifying shell scripts. Covers strict mode, quoting, cross-platform traps (BSD vs GNU), error handling, security, testing.
- Batch file processors: rescue/catch per item, not per batch. One bad file must not crash the tool.
- Don't embed volatile counts (test count, line count, file count) in docs or README. Describe what, not how many.
- When implementing from plan, challenge correctness of stateful operations (counters, file naming, sequencing). Plans are proposals, not specs.
- Platform-specific commands (`open`, `pbcopy`, `stat -f`, `date -j`): grep before shipping shell scripts. Guard with `command -v`.
- Go: default to unexported (lowercase). Only export when cross-package usage is confirmed.
- CLI tools: MUST read `.agents/conventions/cli-guidelines.md` before writing code. Key: stderr for messages, stdout for data. Flags over positional args. Error messages: say what went wrong AND suggest a fix.
- New tools must follow the skeleton in `conventions/cli-guidelines.md § Tool Skeleton`. Reference impl: `tools/dotfiles`.
- CLI tool layering: lower layers never call higher layers. Each independently useful (e.g. `wt` never calls `ag`; `ag` composes `wt`).
- CLI tools: explicit subcommands over positional fallthrough. First arg is always a verb.
- Before adding complexity for environment differences, ask "can I make the environments identical?" Prefer explicit env vars (set by provisioner) over filesystem markers. Edge case count is a design smell.
- Extract shared code when building the 3rd instance of a pattern, not after. Two copies are fine; three means extract now.

## Agent

- Prefer speed/autonomy when working from agreed plan
- Log actions for visibility
- CLI tools: always pass `--no-interactive` or equivalent. Never let a CLI block on stdin.
- Hang detection: run potentially-slow commands in background. Poll output – if no new output for 15s (with verbose/debug flags) or 30s (without), assume hung. Kill, retry with timeout, or fall back.
- Exit loops if no progress toward verifiable goal. Never loop 3+ times on same failure – stop, note pattern, ask.
- Ask before guessing paths/values – don't assume from directory listings.
- Before creating files/dirs, confirm destination with user – especially when "save locally" or "keep it local" is ambiguous between repo, dotfiles, and `~/.agents/artifacts/`.
- Flag over/under-prompting: say so directly.
- For review/planning sessions, present 1–2 decisions at a time, not a full menu.
- When working across repos, confirm target repo early.
- After disruptions (tool rejection, context restore, mode switch, concurrent edits from another tool), verify actual state (git status, git diff, ls) before retrying.
- Before acting on stale state (plan mode entry, artifact rebuild, path additions), verify current state first (`git diff --stat`, check for pending migrations).
- In worktrees: verify edit target matches the worktree. `ag` worktree sessions should edit within the worktree, not the main repo checkout.
- Multi-file tasks (3+ files, distinct context per step): delegate each logical step to a Task subagent with focused context. Inline is fine for <3 files or heavily shared context.
- Subagent constraints: specify scope (test-only, research-only, implement-only) and what NOT to touch.
- When plan references another PR/branch, diff its changes against current branch before shipping.
- Permission denial in autonomous mode: don't retry the same operation. Identify what was blocked, explain what permission it needs, and offer the manual command or suggest user run it interactively. Continue with remaining work that doesn't require the blocked permission.
- Never auto-merge PRs or enable auto-merge. Stop at push/PR creation unless the user explicitly asks to merge now.
- Never auto-post GitHub PR comments/reviews (`gh pr comment`, `gh pr review`) unless the user explicitly asks in the current session.
- Autonomous session end: summarize completed work + remaining items. Send terminal notification so user knows the run finished.
- Start minimal, add when needed. Don't design for consumers that don't exist yet.
- When designing skill boundaries, ask user to describe the full workflow before splitting responsibilities.
- Renames: confirm final name before editing files. Name churn with partial edits costs O(files × renames).
- Cross-repo tasks: create branches in all target repos before making any edits.
- When work spans repos, write session note with exact change specs for the second repo before ending.
- For structural changes (moving code, renaming paths, changing seed locations), grep-audit all read/write/seed paths across files before implementing.
- When user feedback is vague about which element to fix, show what you're about to change and confirm scope before implementing. Progressive specificity: let the user narrow, don't guess.

### Interruption routing

When a side idea or tangent surfaces mid-task, route by blast radius:

- **Trivial** (typo fix, alias addition, small refactor in current file): do it inline, now
- **Low** (self-contained task, different file/module): delegate to a subagent, continue main work
- **Medium** (new feature, cross-cutting change, needs its own branch): log to INBOX.md, finish current task first
- **High** (new system, architectural change, multi-session effort): log to INBOX.md with enough context to /propose later. Never start mid-session.

Default to higher blast radius when uncertain. The cost of context-switching is almost always higher than the cost of deferring.

## Modes

- `learn [topic]` → Socratic teaching, tests understanding. See /learn.
- `walkthrough [topic]` → Opinionated code walkthrough. See /walkthrough.
- `eli5 [topic]` → Simplest first, I'll ask deeper.
- `teach` (during execute) → Narrate changes with inline code refs. See /execute modes.
- `poc <idea>` → Prove it works. Feasibility research → minimal build → draft PR with gaps documented. Single branch, no stacking. Requires `ccy`.
- `steelman [decision]` → Structured decision-making. Restate the decision, extract relevant context, present 2-3 serious options, steelman each fairly, recommend one. Include confidence level, reversal conditions, and next validating experiment. Chat output only – no artifact required.
- `grill-me [decision]` → Enumerate all options, ask probing questions to surface real constraints, commit to one recommendation. Deeper than steelman; multi-turn. See /grill-me.
- Plan mode: code exploration + plan writing. For iterative design, stay in execute mode unless codebase scanning drives the discussion. Let user drive pacing; don't rush to formalize.
- Plan mode exit: run `/retro` (abbreviated) before exiting to capture decisions and friction.

## Workflow

Checkpoint is the only release path – route through /checkpoint skill. Never bare commit+push.

### Pipeline

Skills chain: /propose → /tidy → /execute → /checkpoint → /review. Each produces artifacts; `ag run <topic>` composes them. Full spec: `~/.agents/docs/circus.md`.

### Splitting changes
Branch naming: `<type>/<slug>`. All changes to main require a PR.
Prefer splitting logically independent changes into stacked PRs. Proactive: branch separable changes immediately. Retroactive: untangle at checkpoint.
MUST read `conventions/workflow.md § Stacked PRs` for Graphite commands and stack rebase patterns.

### Retro
Auto-trigger at checkpoint, session end, and before context-loss events (exiting plan mode, switching repos/tasks, long break). Full at checkpoint; abbreviated before context loss.

## Stack

Primary: Go, TypeScript. Bazel build. Kubernetes, OpenAPI, gRPC.
Use as reference frame – draw analogies to these when explaining new tech or making design decisions.

## Testing

- TDD for core logic – write tests first, use as guardrails for autonomous work
- Table-driven tests (Go)
- No heavy mocks. If it needs mocks, rethink the boundary
- Integration tests: opt-in. Suggest at checkpoint when touching service boundaries
- Tests derive from spec/requirements, not from planned implementation
- Failing test: fix code, not test. Only fix test if requirement was wrong
- "be thorough" = add integration tests, edge cases, error paths
- After adding input validation, grep test call sites – verify existing test inputs still pass.
- `bash -n` is syntax only; mentally trace execution context, platform, and edge cases before shipping.
- TDD greps/pattern checks are scaffolding; ship behavioral tests that verify output, not source patterns.
- If a test needs a workaround to pass, fix the code under test, not the test.
- Shell/dotfiles testing: see `conventions/shell-scripts.md` § Testing.

## Safety

In all modes:
- Never `rm -rf` outside of build/temp dirs. Always scoped, never `~/` or `/`.
- Never `git push --force` to main/master or shared branches.
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
- In execute mode (main agent): never commit without user confirmation – show diff, summarize, wait for go-ahead.
- Before branch operations (checkout, rebase): `git diff --stat` to confirm clean state.
- Before committing, verify current branch matches intent – check for open PRs, whether the PR is already merged, and whether changes belong there. `git diff --cached --stat` to verify only intended files staged.
- `settings.json`: never stage the `model` field (session-local, toggled via /model).
- First push on new branch: check `@{upstream}` – if unset, use `-u origin <branch>`.
- Git hygiene aliases (`dotfiles/shell/zshrc`): `gm` (main + pull + full cleanup), `gsync` (rebase onto main), `gclean` (cleanup only). For Graphite stacks, use `gtr` not `gsync`.
- Hygiene aliases are safe anytime. Push operations (`gpush`, `gpushup`) only through /checkpoint.
- MUST read `conventions/git-recipes.md` for advanced git ops. Key: --force-with-lease stales after rebase (use --force on personal branches), don't stash across branches, gh must run from target repo cwd.

## Pull Requests

- Title: conventional commit format, under 70 chars. Describe capability, not file diff.
- PRs are accomplishment records – what the system can now do, not a line-by-line diff of file changes
- Model-first: describe the system model the PR establishes or changes (concepts, relationships, invariants), not what files were touched
- Design decisions: source from design doc/plan artifacts. State final decision with rationale and alternatives considered, not ad-hoc
- Visual aids where they help: tables for cases/logic the reviewer needs to think through; diagrams for data flow, state machines, hierarchies. Don't overdo it
- Stacked PRs: note position in the series and dependencies
- Body structure:
  ```
  ## Motivation
  <why – problem, need, or gap. Link to issue/design doc>

  ## What this does
  <system model – concepts, relationships, invariants>
  <tables for case logic, diagrams for flow – only when they help>
  <capabilities enabled, behavioral shifts>

  ## Design decisions
  <from design doc/plan – choices, rationale, alternatives>
  <skip for trivial PRs>

  ## Test plan
  - [ ] <how to verify>
  ```
- Reference issue numbers when applicable
- After pushing follow-up commits, update the PR body to reflect new changes
- Descriptions = current intent, not changelog. No "what changed from v1" sections. Commit history handles evolution.
- Before `gh pr edit --body`: always `gh pr view --json body` first, diff new content against existing, merge. GitHub has no edit history; overwriting destroys user content permanently.

## Memory

Model: session → INBOX.md (short-term) → triage → AGENTS.md (long-term)

- AGENTS.md = long-term memory. Cross-tool, synced via dotfiles. Only triage writes here.
- INBOX.md (`~/.agents/INBOX.md`) = short-term capture. Local, never synced.
- retro = capture process → INBOX.md. triage = promotion → AGENTS.md or discard.
- Triage when INBOX.md exceeds ~10 items. Proactively check and suggest `/triage` when it's growing – don't wait to be asked.
- At triage, gate each item: work-specific → AGENTS-work.md, personal → AGENTS.md. MUST read `conventions/agents-md-guidelines.md` before promoting. Key: AGENTS.md must stay under 200 lines; never leak work-only tools/repos.
- Skills (shared workflows) live in `~/.agents/skills/` – both Claude Code and Cursor read from here. Skill frontmatter must include `name` + `description` at minimum (Codex enforces).
- Skill vs instruction: single command + context → AGENTS.md instruction. Multi-step, branching logic, or cross-repo → skill. MUST read `conventions/skill-guidelines.md` before writing/modifying skills. Key: frontmatter needs name + description, document blast radius.
- When updating a skill or its reference example, diff conventions against the artifact to catch drift.

Artifacts:
- `~/.agents/artifacts/<topic>/` = all artifacts. MUST read `conventions/artifact-templates.md` when creating. Key: frontmatter needs topic + status + created fields.
- `load <topic>` → search artifacts/, docs/, sessions/, notes/. Partial match; ambiguous → show options.
- `~/.agents/docs/` = persisted reference docs, synced via dotfiles. Mature artifacts graduate here at checkpoint.
- `conventions/workflow.md` – full workflow reference, on demand.

Capture:
- `log <thought>` → agent appends to INBOX.md (date, context, idea). Not a shell alias – agent writes via bash.
- `win: <description>` → agent appends to `~/.agents/wins.md` (promo-packet worthy).
- Self-resolve friction once. If reusable, suggest INBOX.md entry.

## Dotfiles

Personal dotfiles repo (`justin252/dotfiles`): universal base layer. Work dotfiles overlay via separate install.sh. Overlays are optional; this repo works standalone.

- MUST read `conventions/dotfiles.md` before modifying dotfiles, install.sh, tools, or shell config. Key: install.sh is idempotent, symlinks not copies, mkdir -p before loops, test with sandbox.sh.
- `~/.zprofile` is machine-local (tool installers like brew, pipx, volta own it). Dotfiles manage zshrc, not zprofile.

### Reference library

On-demand context in `~/.agents/conventions/` and `~/.agents/docs/`. Read when triggered; never auto-load. AGENTS-work.md extends with work-specific entries.
