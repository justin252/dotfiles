---
topic: circus
status: active
created: 2025-06-01
updated: 2026-03-16
---
# Design: The Circus

Your brain decides what to build. The circus handles everything else.

Each animal is a specialist. 🦊 doesn't become 🦅 – it finishes and hands off. Artifacts are the interfaces between them.

```
Coordinators (one each):
  🐙 you            /propose         problem.md → design.md → plan.md
  🦁 dispatch        (future)         decompose plan, monitor + nudge workers
  🦫 branch mgmt     (future)         rebase, restack, detect conflicts → delegate to 🦊

Workers (many, parallel):
  🦊 implement       /execute         code changes, tests, fixes
  🐝 swarm           (future)         repetitive sub-tasks (rename across 40 files, migrate 20 services)

Per-pipeline (scale with workers):
  🦅 ship            /checkpoint      build, test, PR, output.md (automatic, no human gate)
  🦉 review          review (async)   review.md
  🐘 learn           /retro, /triage  INBOX.md → AGENTS.md
```

---

## Today: The Composable Pipeline (`/run`)

One command. Full pipeline. Learning at every phase transition.

```bash
# 🐙 Design (still interactive)
ccplan
/propose auth                             # iterate until plan.md exists
# /propose: "Plan ready. Run: ag run auth"

# 🎪 Full pipeline
ag run auth                               # discovers plan.md, full pipeline
```

`ag run <topic>` finds `~/.agents/artifacts/<topic>/plan.md`, creates a worktree, and launches `/run`. No paths, no prompts. Multi-source plan picker: artifacts, cursor plans, claude plans – sorted by last modified, fzf with preview.

`/run` is the ringmaster. 🦅 is automatic. The only human gate is **merge**.

```
/run plan.md
  │
  ├─ DESIGN CHECKPOINT     scan plan.md ## Open → INBOX.md
  ├─ 🦊 /execute            implement from plan
  ├─ 🦅 /checkpoint          auto-ship: build, test, PR, output.md, /retro → INBOX.md
  ├─ 🦉 review (async)       → review.md
  │     └─ if issues:        new 🦊 reads review.md, pushes fixes to same PR
  │                           🦅 auto-ships again, 🦉 re-reviews (1 cycle max)
  ├─ 🐘 /retro               INBOX.md (from every phase)
  └─ NOTIFY                  "PR #47 ready for merge. 3 INBOX items captured."
```

You come back to: a PR ready for teammate review, `review.md`, INBOX entries from every phase, `output.md` linking everything.

### Configuration

Per-stage executor/model via `AG_*` env vars in `shell/zshrc`. Format: `executor:model`.

```bash
# ─── Agent Stages (executor:model) ───────────────────────────
# Claude: --model (opus, sonnet, haiku)
# Codex: -m (gpt-5.4, gpt-5.3-codex, gpt-5.3-codex-spark)
export AG_EXECUTOR="claude:opus"           # 🦊 execute
export AG_SHIPPER="claude:sonnet"          # 🦅 ship
export AG_REVIEWER="codex:gpt-5.4"        # 🦉 review
export AG_LEARNER="claude:haiku"           # 🐘 retro
```

**CLI flags** (override env):
```bash
ag run auth --codex --skip review    # executor + stage skipping
```

Priority: CLI flag > stage env var > default (`claude`).

`ag run` exports all `AG_*` vars into the tmux session + derives `CLAUDE_CODE_SUBAGENT_MODEL` from `AG_LEARNER` for Task delegation.

### Status reporting

```
$ ag status
  auth      🦊 implementing (3/7 tasks)     feat/auth
  config    🦅 shipping                      feat/config
  middleware 🦉 reviewing (async)            feat/middleware  PR #47
  cache     ✅ done                           feat/cache      PR #42 merged
```

Tmux status bar: `auth🦊● config🦅● middleware🦉○`. At scale, this is how you stay oriented without attaching to each session.

---

## The Full Picture (future)

```
You (🐙 design)
  │  /propose → plan.md
  ▼
🦁 decomposes plan, dispatches + monitors workers:
  ├──▶ ag run feature-a  ──▶ 🦊→🦅→🦉→(🦊 fix)→🦉→🐘
  ├──▶ ag run feature-b  ──▶ 🦊→🦅→🦉→🐘
  └──▶ ag run config     ──▶ 🐝→🦅
              │
  🦫 keeps PRs mergeable (background, event-driven):
  │   ├─ rebase onto latest main
  │   ├─ restack stacked PRs after parent merges
  │   ├─ resolve trivial text-level conflicts
  │   └─ CI failure / semantic conflict? → delegate to 🦊
              │
  🐘 captures learning from each pipeline
              │
  Teammate reviews + merges
              │
  ◄──── AGENTS.md feeds back to you ────╯
```

🦁 dispatches AND monitors (no separate Wolf – at this scale, dispatch + nudge is one job). Each `ag run` is a complete pipeline. 🦫 never writes code – it manages branches/stacks and delegates code fixes to 🦊. Merge queue is infrastructure (GitHub), not 🦫. Teammate reviews and merges. 🐘 closes the learning loop.

---

## Model Selection

Which model for which animal. The key insight: different benchmarks measure different capabilities, and the rankings shift dramatically between them. A model that leads one benchmark can trail by 16 points on another.

### Benchmarks (March 2026)

| Benchmark | Measures | Leader | Gap |
|-----------|----------|--------|-----|
| SWE-bench Verified | Bug-fix in real repos | Opus 4.5 80.9% | Top 5 within 1% |
| SWE-bench Pro | Harder, less contaminated | GPT-5.3-Codex 56.8% | 11pt over Opus 4.5 (45.9%) |
| Aider Polyglot | Multi-lang coding, 6 languages | GPT-5 high 88.0% | 16pt over Opus 4 (72.0%) |
| Terminal-Bench 2.0 | Autonomous terminal execution | Gemini 3.1 Pro 78.4% | GPT-5.3-Codex 77.3%, Opus 4.6 74.7% |

SWE-bench Verified (where Claude leads) has confirmed training data contamination across all frontier models. SWE-bench Pro and Aider Polyglot are cleaner signals. Terminal-Bench measures the autonomous agent loop that `/run` actually uses.

Sources: [SWE-bench](https://www.marc0.dev/en/leaderboard), [Aider](https://aider.chat/docs/leaderboards/), [Interconnects: Opus 4.6 vs Codex 5.3](https://www.interconnects.ai/p/opus-46-vs-codex-53).

### Per-role recommendations

**🐙 Octopus – Design** → **Opus 4.6** via Claude Code (interactive)

Design needs deep architectural reasoning over multiple turns, understanding vague intent, and ingesting entire codebases before proposing structure. This is Opus's genuine differentiator. Extended thinking dynamically scales reasoning depth – shallow for quick questions, deep for "how should we decompose this service." 1M context holds an entire codebase in working memory. Outperforms GPT-5.2 by ~144 Elo on GDPval-AA (economically valuable knowledge work). o3-pro with high compute matches on isolated reasoning but is weaker at multi-turn conversational iteration – design is a conversation, not a single prompt.

Runner-up: o3-pro (high). Strong isolated reasoning, less conversational.

**🦁 Lion – Dispatch** → **Sonnet 4.6 or Haiku 4.5** via Claude Code subagent

Orchestration doesn't need frontier intelligence. It needs fast, reliable structured output (JSON task decomposition), good tool use for monitoring agent status, and low latency for frequent small calls. Sonnet 4.6 at 79.6% SWE-bench Verified is massive overkill for "parse plan.md and fan out tasks." Haiku would work and respond faster. The quality ceiling is your plan.md structure, not the model – dispatch is prompt-engineering-dominated.

Runner-up: GPT-4o. Fast structured output, but different tool-use format adds integration friction without meaningful quality gain.

**🦫 Beaver – Branch Mgmt** → **GPT-5.3-Codex** via Codex CLI (sandboxed)

Beaver is pure terminal execution: rebase, restack, detect conflicts, run git commands autonomously. Terminal-Bench 2.0 measures exactly this – GPT-5.3-Codex scores 77.3%, Opus 4.6 74.7%. But the decisive advantage is architectural, not benchmark: Codex CLI runs each task in an isolated cloud sandbox. Autonomous git operations (force-push, rebase, restack) are dangerous – sandbox isolation means a bad rebase can't corrupt your local worktree. Claude Code runs in your terminal with full filesystem access, making autonomous git ops riskier. Beaver is the strongest case for Codex over Claude regardless of model benchmarks.

Runner-up: Gemini 3.1 Pro (78.4% Terminal-Bench – highest score – but no equivalent sandboxed CLI tool exists).

**🦊 Fox – Implement** → **GPT-5 high / GPT-5.3-Codex** via Codex CLI (autonomous)

The largest gap in the data. Aider Polyglot: GPT-5 high 88.0% vs Opus 4 72.0% (16pt). SWE-bench Pro: GPT-5.3-Codex 56.8% vs Opus 4.5 45.9% (11pt). Both benchmarks are less contaminated than SWE-bench Verified. GPT-5's raw multi-language coding ability is measurably stronger on the cleaner evaluations. Codex CLI's parallel sandbox model lets you run multiple Fox instances without local state conflicts. Codex excels specifically at following clear, scoped specs – which is exactly what Fox gets from 🐙's plan.md. "Make the authentication better" fails on Codex; "implement JWT refresh with 15-min expiry per design.md section 3" succeeds.

Claude Opus compensates with better multi-file refactoring and understanding ambiguous specs. If plan.md is vague or requires reasoning about the full codebase beyond what's written down, Claude wins. But the whole point of 🐙 is to write a good plan – if 🐙 does its job, Fox needs execution precision, not intent-guessing.

Runner-up: Opus 4.6 via Claude Code. Better when plan is ambiguous or deep codebase reasoning is needed mid-implementation.

**🐝 Bee – Swarm** → **Haiku 4.5** via Claude Code subagent

High fan-out, low complexity per task. Renaming across 40 files, migrating 20 API calls. The dominant factor is throughput, not intelligence. Haiku 4.5 has the lowest initial latency among capable coding models. Gemini 2.5 Flash matches Sonnet-class coding quality at 1/3 the cost with 1M context. DeepSeek V3.2 (74.2% Aider Polyglot, ~30x cheaper than GPT-5) is viable if self-hosting. For the tasks Bee handles, even a mid-tier model is overkill – the ceiling is the task, not the model.

Runner-up: Gemini 2.5 Flash. Best value if cost ever matters.

**🦅 Eagle – Ship** → **Sonnet 4.6** via Claude Code subagent

Eagle needs reliable tool use (build commands, test runners, `gh` CLI) and good writing (PR descriptions, output.md). Sonnet 4.6 at 79.6% SWE-bench Verified delivers Opus-class capability at Sonnet speed. PR descriptions need prose quality – Claude consistently beats GPT in blind writing comparisons (67% win rate). Eagle also runs `/retro`, which needs pattern recognition over session history. Writing and synthesis are Claude strengths independent of coding benchmarks.

Runner-up: GPT-5.3-Codex. Strong on terminal execution, weaker on prose composition.

**🦉 Owl – Review** → **Sonnet 4.6** via Claude Code, or **existing Codex `review` tool**

Code review needs deep reading comprehension and architectural awareness across large diffs. Sonnet 4.6 "delivers Opus-class code review quality at Sonnet pricing" (multiple independent reports). 1M context lets it hold entire PRs with surrounding context. Dedicated review tools (Propel F-score 64%, CodeRabbit) outperform raw models on review benchmarks by using specialized prompting – the existing `review` tool (Codex-based, async, artifact-aware) already does this.

Runner-up: Opus 4.6 for complex architectural reviews. Overkill for most PRs.

**🐘 Elephant – Learn** → **Haiku 4.5 or Sonnet 4.5** via Claude Code subagent

Pattern recognition over session history, writing INBOX.md entries, identifying signal vs noise. Doesn't need frontier reasoning – needs good summarization. Claude models are consistently strong at synthesis. Haiku handles simple retros; Sonnet for end-of-session deep reflection. Learning quality depends more on what context you feed it than model capability.

Runner-up: any mid-tier model.

### Two-tool architecture

The recommendations naturally split into two execution environments:

```
Claude Code (conversational backbone)     Codex CLI (autonomous executor)
  🐙 Design      Opus 4.6                  🦫 Branch    GPT-5.3-Codex
  🦁 Dispatch    Sonnet/Haiku               🦊 Implement  GPT-5 (high)
  🐝 Swarm       Haiku 4.5
  🦅 Ship         Sonnet 4.6
  🦉 Review       Sonnet 4.6 or Codex
  🐘 Learn        Haiku/Sonnet
```

Pipeline flow: **Claude designs** (🐙) → **Codex builds** (🦊) → **Claude ships and reviews** (🦅🦉). Artifacts (plan.md, output.md, review.md) are the interface – no API-level integration needed.

### What's configurable today

| Mechanism | Scope | Status |
|-----------|-------|--------|
| `AG_EXECUTOR` env var | executor:model for execute stage | working |
| `AG_SHIPPER` env var | executor:model for ship stage | working |
| `AG_REVIEWER` env var | executor:model for review stage | working |
| `AG_LEARNER` env var | executor:model for retro stage | working |
| `ag run --claude/--codex` | executor override | working |
| `CLAUDE_CODE_SUBAGENT_MODEL` | subagent model (auto-derived from AG_LEARNER) | working |
| `agent:` in plan.md frontmatter | executor per pipeline | working (legacy) |
| `tools/ag-run-stages` | multi-executor stage orchestrator | built, not yet wired into ag run |

**Default path today**: `ag run <topic>` uses Claude Code (Opus) for the single-agent `/run` pipeline. Per-stage models are set via `AG_*` env vars. `ag-run-stages` enables sequential multi-executor stages.

### Extension points (not yet built)

**Wire `ag-run-stages` into `ag run`** – when stage env vars differ across executors, `ag run` delegates to `ag-run-stages` instead of launching a single `/run` session.

**`ag status --remote`** – live SSH query for cross-machine status visibility.

**State file sync** – rsync `~/.agents/state/` from workspace on `pull-dot` or `ag status`.

### What matters more than model choice

The top 5 models on SWE-bench Verified score within 1.3 points. This means **harness and prompt design dominate model choice** for most coding tasks. Your plan.md quality (🐙), your skill prompts (/execute, /checkpoint), and your artifact interfaces determine more of the outcome than whether Fox runs Opus or GPT-5. The model selection above optimizes the margins – real gains come from the pipeline design.

---

## Build Order

| # | What | Why | Depends on |
|---|------|-----|------------|
| 1 | ~~`/run` skill + `ag run`~~ | Full single-agent pipeline. The atomic unit everything scales from. | Composes existing skills |
| 2 | ~~Smart `ag status` + tmux bar~~ | Phase-aware status + tmux dashboard (`C-a a`). | `ag run` |
| 3 | 🦫 Branch/stack management | Already hitting stale bases + conflicts with parallel agents. | Nothing |
| 4 | GUPP-lite (crash safety) | Work survives context exhaustion. Agent resumes from checkpoint. | Nothing |
| 5 | 🦁 Dispatch + monitor | Decomposes plan.md, fans out `ag run`, nudges stuck. Plan in, PRs out. | GUPP-lite, better with 🦫 |
| 6 | 🐝 Swarm | Ephemeral workers for high-fan-out sub-tasks (renames, migrations). | 🦁 + 🦫 |

```
Stage 6.5 (today): ag run <topic>. Full pipeline, learning everywhere.
Stage 7 (🦁):      Dispatch fans out ag run. 🦫 keeps PRs healthy.
Stage 7+ (full):   You only design and approve.
```

---

## Active Plans

- **[Model config + workspace support](~/.agents/artifacts/circus/plan.md)** – per-stage executor selection, workspace routing fixes, cross-executor orchestrator. Three tiers: model hints (now), pipeline config (Tier 2), `ag-run-stages` (Tier 3).
