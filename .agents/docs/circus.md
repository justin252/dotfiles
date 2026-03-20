---
topic: circus
status: active
created: 2025-06-01
updated: 2026-03-20
---
# Design: The Circus

Your brain decides what to build. The circus handles everything else.

Each animal is a specialist with its own identity and memory. 🐕 doesn't become 🦅 – it finishes, self-reflects, and hands off. Artifacts are the interfaces. Learning is continuous.

## Animals

```
Pipeline (work production):
  🐙 octopus    /propose         design: problem.md → design.md → plan.md
  🦫 beaver      /tidy            branch health: diagnose, rebase, restack
  🐕 dog         /execute         implement: code changes, tests, fixes
  🐝 bee         (future)         swarm: repetitive sub-tasks at scale
  🦅 eagle       /checkpoint      ship: build, test, PR, output.md
  🦉 owl         /review          review: review.md

Coordinator:
  🦁 lion        /lion            dispatch: reads manifests, picks animal + environment, drives ag/wt

Curator:
  🐘 elephant    /triage          evaluate + graduate learnings across all animals
```

Each animal is independently useful. The pipeline is one way to compose them.

---

## Core Model

### Animal = identity. Skill = behavior.

An animal is a role with accumulated experience. A skill is a specific thing that role does. One animal can own multiple skills.

```
🐘 elephant
  └─ /triage (skill: sort and graduate learnings)

🐕 dog
  └─ /execute (skill: implement from plan.md)
  └─ (future: /hotfix, /resolve-conflict)
```

The animal carries identity and memory across all its skills. Adding a new capability to an existing animal = add a skill; the animal's learnings inform it automatically.

### Circus.md is the registry

This file is the single source of truth for pipeline metadata – animal assignments, ordering, handoffs, model selection. Individual SKILL.md files stay minimal (name + description only). No frontmatter manifests in skills.

Why: skills are independently useful outside the pipeline. Encoding pipeline position in skill frontmatter couples them to circus orchestration. Keeping the registry here means one place to update when animals/ordering change.

### Non-circus skills

`explain`, `poc`, `ticket` stay outside the circus. Utilities, not pipeline stages. No animal, no manifest, no learnings.

---

## Learning

Every animal learns. The elephant curates.

### How it works

```
Every animal:  skill epilogue (## Epilogue in SKILL.md)
               → appends 1-3 lines to ~/.agents/learnings/<animal>.md
               → freeform dated entries, fast capture

Elephant:      reads all animal learnings + INBOX.md
               → evaluates significance
               → sees cross-animal patterns no individual can see
               → graduates knowledge to permanent homes
               → consolidates/compresses what's left
```

### Retro is universal

Retro is not a pipeline stage. It's a behavior every animal has – self-reflection after each run. The elephant taught the method (the epilogue template); each animal applies it.

The pipeline is pure work production:
```
🐙 design → 🦫 branch → 🐕 implement → 🦅 ship → 🦉 review
```
Learning happens orthogonally, at every stage.

### Elephant as professor

The elephant doesn't just route – it evaluates. Raw learnings are lab reports. The elephant reads across all students and decides:

- Significant finding → graduate (SKILL.md rule, AGENTS.md, AGENTS-work.md)
- Recurring cross-animal pattern → systemic fix (route feedback between animals)
- Noise → compress or discard

### Three triage scopes

**Per-animal:** "Dog keeps hitting stale imports after refactors"
→ graduates to dog's SKILL.md as a checklist item

**Cross-animal:** "Owl keeps finding error handling gaps that dog misses"
→ routes feedback from owl to dog's learnings
→ or updates execute SKILL.md to include error handling pass

**Project-level:** "Auth-related work always takes 3x longer than planned"
→ updates octopus's learnings ("scope auth work at 3x")
→ or AGENTS.md rule if universal

### Promotion destinations

The elephant's decision tree:

1. Universal (any animal could hit this)? → AGENTS.md
2. Specific to one animal's domain, proven (3+ occurrences)? → that animal's SKILL.md
3. Specific but unproven (1-2 occurrences)? → stays in learnings.md
4. Work-specific? → AGENTS-work.md (regardless of tier)

### Learnings are local-only

`~/.agents/learnings/<animal>.md` – local, never synced. Same treatment as artifacts/. This avoids personal/work boundary issues. Everything is staging until the elephant promotes it to a versioned destination.

Format: freeform append (dated entries). Elephant restructures into sections during triage (patterns that work, patterns that fail, cross-animal feedback).

### Capture context

Where a learning is captured determines its initial association:

- **Inside a skill** (epilogue): auto-associates with that animal's learnings.md
- **Regular session** (/retro or manual): goes to INBOX.md. Elephant routes to the right animal during triage.

---

## Infrastructure

### Layers

```
Git aliases       (gm, gsync, gclean – raw git ops, stay dumb)
  → wt            (worktree mgmt – smart branch navigation, environment-aware)
  → wss           (workspace SSH + tmux)
  → ag            (session lifecycle – create, kill, status, dashboard)
  → Lion skill    (dispatch – reads manifests, picks animal + environment, calls ag/wt)
  → Animal skills (execute, review, beaver, etc.)
```

Lower layers never call higher layers. Each independently useful. The lion composes everything below it, but you can always drive manually.

### ag = plumbing

`ag` handles session and worktree infrastructure:
- `ag <name>` – create session + worktree
- `ag kill/clean/restart` – session lifecycle
- `ag status` – dashboard
- `ag pr` – checkout PR into worktree

`ag run <topic>` becomes a thin shell wrapper that launches `/lion`. Dispatch intelligence moves from `ag-orchestrate` to the lion skill. The lion reads manifests, sequences stages, calls ag/wt as needed.

### wt = smart branch navigation

`wt <branch>` is the universal "get me to this branch" command:
- Existing worktree? Navigate there (zero cost)
- Workspace (Linux)? Always create worktree (disk is cheap)
- Laptop (macOS) + small repo? Create worktree
- Laptop + large repo? Warn about disk, suggest workspace

`wt clean` removes merged/stale worktrees. `wt list` shows all with status. Beaver includes worktree hygiene in its diagnostics.

### Environments

A skill doesn't know or care where it runs. The orchestration layer decides.

```
Local:       cc → /execute                     (runs on laptop)
Worktree:    ag <name>                         (isolated branch, same machine)
Workspace:   wss <workspace> → /execute        (remote EC2)
Background:  ag <name> -m "implement plan.md"  (detached tmux)
Pipeline:    /lion run <topic>                 (lion sequences everything)
```

### Workspace state

Laptop is the durable state machine. Workspaces are ephemeral compute.

- Learnings accumulate on workspace during session
- `wss` disconnect hook auto-syncs `~/.agents/learnings/` and `~/.agents/INBOX.md` back to laptop
- No manual sync needed – close session, learnings come home

---

## Today: The Multi-Stage Pipeline

One command. Full pipeline. Per-stage models. Background orchestration.

```bash
# 🐙 Design (interactive)
ccplan
/propose feed-atlas                       # iterate until plan.md exists

# 🎪 Full pipeline
ag run feed-atlas                         # discovers plan.md, full pipeline
ag run feed-atlas --resume                # pick up where it left off
ag run feed-atlas --test                  # integration test with stubs
ag review                                 # standalone review (current branch)
```

`ag run <topic>` finds `~/.agents/artifacts/<topic>/plan.md`, creates a worktree + tmux session, and launches `ag-orchestrate` in the background.

```
ag run feed-atlas
  │
  ag-orchestrate (background):
  ├─ 🐕 claude --model opus '/execute plan.md'
  ├─ 🦅 claude --model sonnet '/checkpoint'
  ├─ 🦉 review --topic feed-atlas (async Codex)
  │     └─ if blockers: 🐕 reads review.md, pushes fixes (1 cycle max)
  └─ NOTIFY  "pipeline complete: feed-atlas"
```

Each stage self-reflects via epilogue. Learnings accumulate locally. State tracked in `~/.agents/state/<slug>/pipeline.json`. Monitor with `ag status`.

### Configuration

Per-stage executor/model via `AG_*` env vars in `shell/zshrc`. Format: `executor:model`.

```bash
# ─── Agent Stages (executor:model) ───────────────────────────
# Claude: --model (opus, sonnet, haiku)
# Codex: -m (gpt-5.4, gpt-5.3-codex, gpt-5.3-codex-spark)
export AG_EXECUTE_MODEL="claude:opus"      # 🐕 execute
export AG_SHIP_MODEL="claude:sonnet"       # 🦅 ship
export AG_REVIEW_MODEL="codex:gpt-5.4"    # 🦉 review
export AG_RETRO_MODEL="claude:haiku"       # 🐘 triage
```

Priority: CLI flag > stage env var > default (`claude`).

### Status reporting

```
$ ag status
  auth      🐕 implementing (3/7 tasks)     feat/auth
  config    🦅 shipping                      feat/config
  middleware 🦉 reviewing (async)            feat/middleware  PR #47
  cache     ✅ done                           feat/cache      PR #42 merged
```

Tmux status bar: `auth🐕● config🦅● middleware🦉○`.

---

## The Full Picture

```
You (🐙 design)
  │  /propose → plan.md
  ▼
🦁 lion dispatches + monitors:
  ├──▶ ag run feature-a  ──▶ 🐕→🦅→🦉→(🐕 fix)→🦉
  ├──▶ ag run feature-b  ──▶ 🐕→🦅→🦉
  └──▶ ag run config     ──▶ 🐝→🦅
              │
  🦫 keeps PRs mergeable (background, event-driven):
  │   ├─ rebase onto latest main
  │   ├─ restack stacked PRs after parent merges
  │   ├─ resolve trivial text-level conflicts
  │   └─ CI failure / semantic conflict? → delegate to 🐕
              │
  🐘 reads all learnings, graduates knowledge
              │
  Teammate reviews + merges
              │
  ◄──── AGENTS.md feeds back to you ────╯
```

🦁 is a skill that composes ag/wt. Each `ag run` is a complete pipeline. 🦫 never writes code – manages branches/stacks and delegates code fixes to 🐕. Merge queue is infrastructure (GitHub), not 🦫. 🐘 is the curator: reads all animal learnings, graduates to SKILL.md/AGENTS.md/AGENTS-work.md.

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

SWE-bench Verified (where Claude leads) has confirmed training data contamination across all frontier models. SWE-bench Pro and Aider Polyglot are cleaner signals. Terminal-Bench measures the autonomous agent loop that the pipeline actually uses.

Sources: [SWE-bench](https://www.marc0.dev/en/leaderboard), [Aider](https://aider.chat/docs/leaderboards/), [Interconnects: Opus 4.6 vs Codex 5.3](https://www.interconnects.ai/p/opus-46-vs-codex-53).

### Per-role recommendations

**🐙 Octopus – Design** → **Opus 4.6** via Claude Code (interactive)

Design needs deep architectural reasoning over multiple turns, understanding vague intent, and ingesting entire codebases before proposing structure. Extended thinking dynamically scales reasoning depth. 1M context holds an entire codebase in working memory. Outperforms GPT-5.2 by ~144 Elo on GDPval-AA.

Runner-up: o3-pro (high). Strong isolated reasoning, less conversational.

**🦁 Lion – Dispatch** → **Sonnet 4.6 or Haiku 4.5** via Claude Code subagent

Orchestration doesn't need frontier intelligence. Needs fast, reliable structured output and good tool use. The quality ceiling is your plan.md structure, not the model – dispatch is prompt-engineering-dominated.

Runner-up: GPT-4o. Fast structured output, different tool-use format adds friction.

**🦫 Beaver – Branch Mgmt** → **GPT-5.3-Codex** via Codex CLI (sandboxed)

Beaver is pure terminal execution: rebase, restack, detect conflicts. Terminal-Bench 2.0: GPT-5.3-Codex 77.3%, Opus 4.6 74.7%. The decisive advantage is architectural: Codex CLI sandbox isolation means a bad rebase can't corrupt your local worktree.

Runner-up: Gemini 3.1 Pro (78.4% Terminal-Bench, no sandboxed CLI equivalent).

**🐕 Dog – Implement** → **GPT-5 high / GPT-5.3-Codex** via Codex CLI (autonomous)

The largest gap in the data. Aider Polyglot: GPT-5 high 88.0% vs Opus 4 72.0% (16pt). SWE-bench Pro: GPT-5.3-Codex 56.8% vs Opus 4.5 45.9% (11pt). Codex CLI's parallel sandbox model lets you run multiple Dog instances. Excels at following clear, scoped specs – exactly what plan.md provides.

Claude Opus compensates with better multi-file refactoring and ambiguous specs. If plan.md is vague, Claude wins. But the whole point of 🐙 is to write a good plan.

Runner-up: Opus 4.6 via Claude Code. Better when plan is ambiguous.

**🐝 Bee – Swarm** → **Haiku 4.5** via Claude Code subagent

High fan-out, low complexity per task. The dominant factor is throughput, not intelligence.

Runner-up: Gemini 2.5 Flash. Best value if cost matters.

**🦅 Eagle – Ship** → **Sonnet 4.6** via Claude Code subagent

Reliable tool use (build, test, `gh` CLI) and good writing (PR descriptions, output.md). Claude consistently beats GPT in blind writing comparisons (67% win rate).

Runner-up: GPT-5.3-Codex. Strong on terminal execution, weaker on prose.

**🦉 Owl – Review** → **Sonnet 4.6** via Claude Code, or **existing Codex `review` tool**

Deep reading comprehension across large diffs. 1M context holds entire PRs with surrounding context. The existing `review` tool (Codex-based, async, artifact-aware) already uses specialized prompting.

Runner-up: Opus 4.6 for complex architectural reviews.

**🐘 Elephant – Curator** → **Sonnet 4.6** via Claude Code subagent

Cross-animal pattern recognition, evaluating significance of learnings, deciding what graduates where. Needs good judgment and synthesis, not raw coding ability. Sonnet balances quality with speed for periodic triage passes.

Runner-up: Haiku for light triage, Opus for deep project-level synthesis.

### Two-tool architecture

```
Claude Code (conversational backbone)     Codex CLI (autonomous executor)
  🐙 Design      Opus 4.6                  🦫 Branch    GPT-5.3-Codex
  🦁 Dispatch    Sonnet/Haiku               🐕 Implement  GPT-5 (high)
  🐝 Swarm       Haiku 4.5
  🦅 Ship         Sonnet 4.6
  🦉 Review       Sonnet 4.6 or Codex
  🐘 Curator      Sonnet 4.6
```

Pipeline flow: **Claude designs** (🐙) → **Codex builds** (🐕) → **Claude ships and reviews** (🦅🦉). Artifacts (plan.md, output.md, review.md) are the interface.

### What's configurable today

| Mechanism | Scope | Status |
|-----------|-------|--------|
| `AG_EXECUTE_MODEL` env var | executor:model for execute stage | working |
| `AG_SHIP_MODEL` env var | executor:model for ship stage | working |
| `AG_REVIEW_MODEL` env var | executor:model for review stage | working |
| `AG_RETRO_MODEL` env var | executor:model for triage stage | working |
| `ag run --claude/--codex` | executor override | working |
| `CLAUDE_CODE_SUBAGENT_MODEL` | subagent model (auto-derived) | working |
| `tools/ag-orchestrate` | multi-executor stage orchestrator | wired into ag run |
| `ag review` | first-class review subcommand | working |

### What matters more than model choice

The top 5 models on SWE-bench Verified score within 1.3 points. **Harness and prompt design dominate model choice** for most coding tasks. Your plan.md quality (🐙), your skill prompts, and your artifact interfaces determine more of the outcome than model selection. The recommendations above optimize the margins.

---

## Build Order

| # | What | Status | Depends on |
|---|------|--------|------------|
| 1 | ~~`/run` skill + `ag run`~~ | shipped | - |
| 2 | ~~Smart `ag status` + tmux bar~~ | shipped | - |
| 3 | ~~Reference library + pipeline in AGENTS.md~~ | shipped | - |
| 4 | ~~Circus.md v2 (this rewrite)~~ | shipped | - |
| 5 | ~~Skill epilogues~~ | shipped (7/10 skills) | - |
| 6 | ~~🦫 Beaver (/tidy)~~ | shipped | - |
| 7 | ~~🐕 Dog rename (fox → dog)~~ | shipped | - |
| 8 | ~~🦁 Lion skill (dispatch)~~ | shipped | - |
| 9 | `wt` environment awareness | next | nothing |
| 10 | `wss` disconnect sync (learnings) | next | nothing |
| 11 | 🐘 Elephant upgrade (three-scope triage) | next | skill epilogues |
| 12 | GUPP-lite (crash safety) | when needed | nothing |
| 13 | 🐝 Bee (swarm) | later | 🦁 + 🦫 |

```
Today:    ag run <topic>. Full pipeline, per-stage models. Lion dispatches.
Next:     wt/wss improvements. Elephant upgrade.
Future:   You only design and approve.
```
