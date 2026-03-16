---
name: explain
description: "📖 Produce a written explanation of a codebase, system, or concept. Saves to ~/.agents/artifacts/<topic>/reference.md. Use when the user says 'explain', 'document this', 'how does X work', or needs a reference doc with code citations."
---

# /explain

Research a codebase or system and produce a reference document with code citations.

## Bootstrap

1. Determine topic: $ARGUMENTS, or infer from conversation context
2. Determine scope: specific file/package, system/service, or concept
3. Read `~/.agents/conventions/artifact-templates.md` for reference.md format
4. Create `~/.agents/artifacts/<topic>/` if missing

## Research

- Read relevant source files, tracing from entry points inward
- Identify key abstractions, data flow, error paths
- Note non-obvious design decisions and constraints
- Check for existing docs (README, godoc, inline comments, ADRs)

## Output Format

Save to `~/.agents/artifacts/<topic>/reference.md`:

```markdown
---
topic: <slug>
status: active
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# <Title>

## Overview
What it does, why it exists. 2-3 sentences.

## Architecture
Key components and how they connect. Diagram if complex.

## Data Flow
How data moves through the system. Entry points, transformations, exit points.

## Key Files
| File | Role |
|------|------|
| `path/to/file.go:42` | Brief description |

## Design Decisions
Non-obvious choices and their rationale. Link to source.

## Gotchas
Things that surprised you or would trip up a new reader.
```

## Principles

- Anchor claims to source code with `file:line` citations
- Explain the why, not just the what – a reader can read code themselves
- Bridge from familiar concepts (Go, TS, Kubernetes patterns per user's stack)
- Concise. A good explain doc is shorter than the code it describes.
- Don't document the obvious. Focus on what's hard to discover by reading.
