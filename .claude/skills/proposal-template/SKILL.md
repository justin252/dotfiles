---
name: proposal-template
description: Write technical design proposals following a cone-pattern structure. Use when drafting RFCs, design docs, architecture proposals, or any document that introduces a system or significant change. Produces a structured markdown document.
---

# Proposal Template

> **Team eventual home:** `domains/mosaic/.claude/skills/proposal-template/SKILL.md`
> Move there when team adopts shared skills in the monorepo.

## Structure (cone pattern)

Write the document following this order. Each section narrows from broad to specific.

### 1. Philosophy
Why this system/change exists. Core belief in one sentence. Include a diagram showing the high-level architecture or layered model. Keep it abstract -- any reader should understand the motivation without domain knowledge.

### 2. Landscape
What else exists in this space (internal initiatives, industry solutions, prior art). Where this proposal fits relative to them. Be explicit about what's complementary vs. independent vs. overlapping. If there's an adoption/integration path with existing initiatives, outline it here.

### 3. Patterns and Research
Research-backed design decisions. Each pattern gets a subsection: name it, cite the source with an inline hyperlink, quote the key insight, explain how it applies. No bracket-style citations -- hyperlink directly in prose.

### 4. Architecture (abstract layers)
Explain the system in generic terms any team could adopt. Define each layer/component abstractly. Use diagrams. Don't reference specific products, services, or codepaths yet.

### 5. Concrete Instance
Fill in the abstract layers with your specific stack/product. This is where domain-specific details go: file paths, service names, component relationships, implementation tables.

### 6. Implementation
Phased checklist. Each phase has a theme (foundation, core system, validation, rollout). Separate from the design -- a reader can understand the system without this section. Keep future/aspirational items in a distinct "Future" subsection.

### Appendices
- **Further Reading** -- compact link list (no bracket citations, just grouped inline links)
- **Open Questions** -- numbered, each with enough context to be actionable
- **Version History** -- one line per version, what changed

## Formatting rules

- Inline hyperlinks, never bracket citations. Link the source where it's referenced.
- Diagrams: ASCII art in fenced code blocks (renders everywhere).
- Tables for structured comparisons (components, status, roles).
- Frontmatter-style header: status, repo, branch.
- Concise -- cut anything a smart reader can infer. No narrating what the doc does.
