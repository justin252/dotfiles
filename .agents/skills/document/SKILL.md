---
name: document
description: "Produce a written reference doc for a codebase, system, or concept. Draft saved to artifacts, graduates to docs/ after review. Use when user says 'document this', 'write a reference', or needs a standalone knowledge doc."
---

# /document

Research a codebase or system and produce a reference document with code citations.

## Bootstrap

1. Determine topic: $ARGUMENTS, or infer from conversation context
2. If no topic: suggest 2-3 candidates from cwd (recent files, modules, key dirs)
3. Determine scope: specific file/package, system/service, or concept
4. If prior `/walkthrough` context exists in conversation, build on those insights
5. Read `~/.agents/conventions/artifact-templates.md` for reference.md format
6. Create `~/.agents/artifacts/<topic>/` if missing

## Research

- Start from entry points, trace inward
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

For each important file, use anchored citations:

**`path/to/file.go:42-51`** – brief description

\```lang
<relevant snippet>
\```

What this does and why it matters.

## Design Decisions
Non-obvious choices and their rationale. Anchor to source with file:line.

## Gotchas
Things that surprised you or would trip up a new reader.
```

## Principles

- Anchor claims to source code with `file:line` citations + inline snippets
- Explain the why, not just the what – a reader can read code themselves
- Bridge from familiar concepts (Go, TS, Kubernetes patterns per user's stack)
- Concise. A good reference is shorter than the code it describes.
- Don't document the obvious. Focus on what's hard to discover by reading.

## Next

On completion: `Reference saved. /propose if it reveals a problem to solve`
