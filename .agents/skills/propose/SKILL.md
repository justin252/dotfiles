---
name: propose
description: "🐙 Create or continue the problem → design → plan pipeline at ~/.agents/artifacts/<topic>/. Use when the user says 'propose', 'design', 'rfc', or needs to think through a system before building it."
---

# /propose

Research, then produce artifacts at `~/.agents/artifacts/<topic>/`. Context-aware – picks up where the pipeline left off.

## Bootstrap

1. Read `~/.agents/AGENTS.md` for conventions
2. Read `~/.agents/conventions/artifact-templates.md` for doc format
3. Determine topic from $ARGUMENTS or conversation context
4. Create `~/.agents/artifacts/<topic>/` if missing
5. Check what exists and pick up there:
   - **Nothing**: start with problem.md
   - **problem.md**: read it, continue to design.md
   - **design.md**: read it + problem.md, continue to plan.md
   - **plan.md**: offer to revise or hand off to /execute
   - Offer to start fresh if user wants to rethink

## Workflow

1. Scan codebase for related systems, prior art, existing docs
2. Ask 2-3 focused questions to clarify scope (skip if context is clear)
3. Draft iteratively – present each section, refine
4. Write the next doc in the pipeline
5. If plan.md is reached, offer /execute handoff

## Scaling

Match verbosity to problem size:
- **Quick task** (alias, config change, small fix): lightweight problem.md (3-5 lines), skip design.md, go straight to plan.md
- **Medium** (feature, refactor, tool): problem + design, maybe combined
- **Large** (system, architecture, multi-session): full pipeline with all sections

## Doc Formats

See `~/.agents/conventions/artifact-templates.md` for canonical templates. Key points:

- All docs use YAML frontmatter (topic, repo, component, status, created, updated, chain)
- Each actionable type has ## Open for unresolved questions
- chain field shows position: `problem.md → **design.md**`

## Principles

- Most important information first. Problem statement should stand alone.
- Concise. Cut anything a reader can infer.
- ## Open sections are for real blockers/decisions, not wishlists.
- Design tradeoffs: state what was considered, what was chosen, why.
- Plan phases feed directly to /execute.

## Next

## Epilogue

Append 1-3 lines to `~/.agents/learnings/octopus.md`: what worked in the design process, what was underspecified, what surprised you.

## Next

On completion, print: `🐕 Plan ready. Next: ag run <topic> or /execute`
