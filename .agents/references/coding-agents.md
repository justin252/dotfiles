# Coding Agents Landscape

Standing reference for coding agent selection, config portability, and multi-tool strategy. Data as of March 2026.

## Tier Ranking

| Tier | Agent | Type | Model | Best for |
|------|-------|------|-------|----------|
| **1** | Claude Code | CLI | Opus 4.6, Sonnet 4.6 | Hard problems, multi-file refactors, config-as-code |
| **1** | Codex CLI | CLI | GPT-5.3-Codex | Speed, terminal tasks, native AGENTS.md |
| **1** | Cursor | IDE | Multi-model | Daily feature work, visual iteration |
| **2** | Gemini CLI | CLI | Gemini 3.1 Pro | Tool coordination, competitive coding, free tier |
| **2** | Windsurf | IDE | Multi-model | Budget IDE teams ($15/mo) |
| **2** | Cline | IDE (OSS) | BYOM | Cost control, provider flexibility |
| **2** | Copilot | IDE | GPT-4o | Pragmatic team default ($10/mo) |
| **3** | Aider | CLI (OSS) | Multi-model | Lightweight, git-native workflows |
| **3** | Devin | Cloud | Proprietary | Well-defined repetitive tasks |
| **3** | OpenCode | CLI (OSS) | 75+ providers | Plan-first development |

## Benchmarks

| Benchmark | Measures | Leader | Score |
|-----------|----------|--------|-------|
| SWE-bench Verified | GitHub issue resolution | Opus 4.6 | 80.8% |
| Terminal-Bench 2.0 | CLI agent tasks | Codex CLI | 77.3% |
| LiveCodeBench Elo | Competitive programming | Gemini 3.1 Pro | 2,887 |
| MCP Atlas | Tool-use reasoning | Gemini 3.1 Pro | 69.2% |
| τ²-bench Retail | Domain reasoning | Opus 4.6 | 91.9% |
| GDPval-AA Elo | Expert task reasoning | Opus 4.6 | 1,606 |

Detailed rankings:
- SWE-bench: Opus 4.6 (80.8%) > Codex 5.3 (~80%) > Sonnet 4.6 (79.6%) > GPT 5.4 (77.2%) > Gemini 3 Pro (76.2%)
- Terminal-Bench: Codex CLI (77.3%) > Droid+Opus (69.9%)
- MCP Atlas: Gemini (69.2%) > Sonnet (61.3%) > Opus (59.5%)
- Expert reasoning: Opus (1,606 Elo) >> Gemini (1,317 Elo)

**Critical finding**: scaffold > model. Same model (Opus 4.5) scored 17 problems apart in different agent scaffolds. Agent architecture impacts performance 22x more than model choice.

## Memory Systems

| Agent | Mechanism | Scope | Auto-memory | Edit/delete |
|-------|-----------|-------|-------------|-------------|
| Claude Code | CLAUDE.md + `@import` | Global + project | Yes (file-based) | Yes |
| Codex CLI | AGENTS.md hierarchy | Global + project + dir | Yes (SQLite 2-phase) | Consolidation only |
| Gemini CLI | GEMINI.md + Agent Skills | Project | Add-only | No |
| Cursor | `.cursor/rules` + User Rules UI | Project + global (UI) | No | N/A |
| Windsurf | Native Memories | Project | Yes | Unknown |
| Cline | `.clinerules` | Project | No | N/A |
| Copilot | `.github/copilot-instructions.md` | Project | No | N/A |
| Aider | `.aider.conf.yml` | Project | No | N/A |

### Details

**Claude Code** – richest memory model. CLAUDE.md supports `@import` for composing instructions from multiple files. Auto-memory writes per-project memory files with frontmatter metadata. 200K standard, 1M beta context window. 5.5x fewer tokens than Cursor for identical tasks.

**Codex CLI** – SQLite-backed memory with 2-phase pipeline: (1) model extracts raw_memory + rollout_summary to SQLite, (2) consolidation agent updates memory files/skills. AGENTS.md hierarchy: `~/.codex/AGENTS.override.md` > project root > per-dir. 32 KiB default max (configurable). 240+ tokens/sec throughput.

**Gemini CLI** – GEMINI.md context files. Memory is add-only (no edit/delete). Agent Skills use open standard (`SKILL.md` format) for on-demand context. Skills portable across agents (Claude Code, Copilot, Cursor).

**Cursor** – weakest global config. User Rules is plain text in Settings UI; no file-based auto-load for global instructions. `.cursor/rules` for project scope. No `@import`. 360K paying users, 1M+ total. Full codebase indexing.

## Skills / Custom Commands

| Agent | Location | Invocation | Extensible | Format |
|-------|----------|------------|------------|--------|
| Claude Code | `~/.claude/skills/` | `/skillname` | Yes | Flexible (MCP-first) |
| Codex CLI | `.agents/skills/` | `/` or `$` | Yes | Open standard |
| Gemini CLI | Skill dirs | Slash commands | Yes | SKILL.md (open standard) |
| Cursor | N/A | N/A | No | Rules approximate |
| Copilot | N/A | Built-in only | Via Actions | N/A |

**Portability**: Claude Code and Codex CLI share `.agents/skills/`. Gemini CLI's SKILL.md open standard (originally proposed by Anthropic) is compatible with `.agents/`. Cursor requires copying (symlink bug).

## Config-as-Code Compatibility

How well each supports an AGENTS.md/INBOX/triage workflow:

| Agent | Native AGENTS.md | @import | Global file config | Skills from `.agents/` | Rating |
|-------|------------------|---------|--------------------|-----------------------|--------|
| Claude Code | Via @import | Yes | Yes (CLAUDE.md) | Via symlinks | **Excellent** |
| Codex CLI | Native | No | Yes (~/.codex/) | Native | **Excellent** |
| Gemini CLI | No (GEMINI.md) | No | Partial | Compatible | **Good** |
| Cline | No | No | No | No | Fair |
| Windsurf | No | No | Partial | No | Fair |
| Aider | No | No | Yes (YAML) | No | Fair |
| Cursor | No | No | No (UI paste) | Copied | **Poor** |
| Copilot | No | No | No | No | **Poor** |

### Distribution Strategy

```
~/.agents/AGENTS.md              <- source of truth
  Claude Code     @import via CLAUDE.md
  Codex CLI       reads ~/.codex/AGENTS.md or repo AGENTS.md
  Cursor          paste into User Rules (manual)
  Gemini CLI      separate GEMINI.md (translate conventions)

~/.agents/skills/                <- merged personal + work
  Claude Code     symlinks from ~/.claude/skills/
  Codex CLI       reads .agents/skills/ directly
  Cursor          copied to ~/.cursor/skills/ (symlink bug)
  Gemini CLI      SKILL.md format (compatible directory)
```

## Cost Comparison

| Agent | Monthly (heavy use) | Pricing model | Notes |
|-------|--------------------:|---------------|-------|
| Copilot | $10 | Fixed | Most affordable, includes free tier |
| Windsurf | $15–40 | Credits | Spikes for agentic use |
| Codex CLI | $30–60 | Per-token ($6/$30 per M) | 2–4x fewer tokens per task |
| Cursor | $40–100+ | Credits | Unpredictable |
| Gemini CLI | $10–50 | Per-token ($1.50–12 per M) | Free preview tier |
| Claude Code | $150–200 | Subscription + per-token | Opus pricing; rate-limited |
| Devin | $50–200+ | $20 base + $2.25/ACU | ACU unpredictable |
| Cline | Provider cost | BYOM | You manage API keys |

Best value: Sonnet 4.6 (79.6% SWE-bench at $3/$15 per M tokens) – near-frontier coding at fraction of Opus cost.

## Strengths & Weaknesses

### Claude Code
- **+** Best instruction-following, deepest config composability (@import), MCP ecosystem (no tool limit), 1M context, top SWE-bench, parallel task decomposition
- **−** Cost ($150–200/mo heavy), no IDE integration (CLI only), MCP Atlas tool-use behind Gemini

### Codex CLI
- **+** Top terminal-bench, native AGENTS.md, SQLite memory with consolidation, 240+ tok/s throughput, open-source
- **−** Shallow reasoning on complex refactors, usage limits (30–150 messages), add-only memory mutations

### Cursor
- **+** Best IDE experience, multi-model, fast iteration UX, codebase indexing, large community (360K paying)
- **−** No file-based global config, no @import, no native skills, symlink bug, unpredictable credit costs, 5.5x more tokens than Claude Code

### Gemini CLI
- **+** Top competitive coding + tool-use, open skill standard, free tier, 1M context
- **−** Lower expert reasoning (1,317 vs 1,606 Elo), add-only memory, stability issues, different config convention

### Windsurf
- **+** Native memories, $15/mo, Arena Mode (blind model comparison)
- **−** Cognition acquisition uncertainty, credit spikes, smaller ecosystem

### Cline
- **+** Open-source (5M VS Code installs), BYOM with zero markup, dual Plan/Act modes
- **−** No native memory/skills, user manages API keys/budgets

### Copilot
- **+** Most deployed (15M devs), works across 5+ IDEs, $10/mo, free for students/OSS
- **−** Least customizable, shallow planning, opaque model choices

### Aider
- **+** 39K GitHub stars, git-native (every edit = commit), multi-model, open-source
- **−** No memory system, no skills, less agentic

### Devin
- **+** Fully autonomous cloud env, 67% PR merge on well-defined tasks
- **−** 85% failure on complex/ambiguous tasks, unpredictable ACU costs

## Multi-Tool Strategy

For the AGENTS.md/INBOX/triage workflow:

1. **Claude Code** (primary) – best config-as-code, @import composes AGENTS.md natively, auto-memory bridges sessions, MCP extensibility. Complex multi-file tasks, planning, autonomous execution.

2. **Codex CLI** (secondary) – native AGENTS.md, strong terminal tasks, review loops, parallel autonomous runs. SQLite memory complements file-based approach.

3. **Cursor** (IDE companion) – rapid iteration, visual diff review, quick edits. Accept config portability tax (paste User Rules, copy skills via `refresh-skills`).

4. **Gemini CLI** (specialist) – tool-use-heavy workflows, competitive coding. Watch open skill standard for convergence with `.agents/`.

### Config Sync

```
dotfiles/install.sh          # distributes AGENTS.md, skills, config
refresh-skills               # rebuilds .agents/skills/, re-syncs Claude/Cursor
pull-dot                     # pulls dotfiles + refreshes everything
```

AGENTS.md is the single source of truth. Each tool reads via its native mechanism (or manual paste for Cursor). Skills in `.agents/skills/` are the portable unit; distribution handled by `refresh-skills`.

## Sources

- SWE-bench: vals.ai/benchmarks/swebench
- Comparisons: morphllm.com/ai-coding-agent, emergent.sh/learn/claude-code-vs-cursor
- Codex memory: mer.vin/2025/12/openai-codex-cli-memory-deep-dive, deepwiki.com/openai/codex/3.7-memory-system
- Gemini skills: geminicli.com/docs/cli/skills
- Cursor rules: docs.cursor.com/context/rules
- Benchmarks: smartscope.blog, morphllm.com/best-ai-model-for-coding, digitalapplied.com
