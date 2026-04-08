# AGENTS.md Writing Guidelines

Rules for maintaining AGENTS.md and AGENTS-work.md. Consult during /triage and /retro when promoting items.

## Compliance constraints

- Instruction compliance decays linearly with volume. Double the rules = half the compliance.
- Ceiling: ~150-200 rules total before compliance collapses.
- Target: AGENTS.md under 200 lines. Currently the binding constraint.
- Always-loaded budget: AGENTS.md + AGENTS-work.md + CLAUDE.md. Every line competes for attention.

## What belongs inline vs in conventions/

- Inline (AGENTS.md): behavioral rules that change Claude's defaults. Short, imperative.
- Convention files: lookup tables, command references, detailed how-to. On-demand.
- Test: "does the agent need this every session?" Yes → inline. No → convention.

## Convention file references

Pattern: `MUST read conventions/X.md before Y. Key: <1-2 critical rules inline>.`
- The MUST-read trigger is probabilistic, not deterministic. The inline key rules are the safety net.
- Works best as pre-task gates (before writing shell scripts). Unreliable mid-flow (during checkpoint).
- For mid-flow templates (PR descriptions): keep fully inline.

## Two-layer system

- AGENTS.md = universal (works standalone on personal machine)
- AGENTS-work.md = work overlay (extends, rarely overrides)
- AGENTS-work.md sections suffixed `(DD)` override corresponding universal sections
- Never leak work-specific tools/repos/infra into AGENTS.md. Heuristic: if it doesn't exist in ~/dotfiles/tools/, it's work.
- When both define behavior for the same action, agents synthesize (merge) rather than pick one. Avoid competing templates; use single source of truth with extensions.

## Adding new rules

Before adding:
1. Is it already covered by an existing rule? (grep AGENTS.md)
2. Can the agent infer it from the codebase? (skip if yes)
3. Is it behavioral (changes defaults) or referential (lookup)? Referential → convention file.
4. Will it push AGENTS.md over 200 lines? If so, what can be moved out?

At /triage:
- Promote to AGENTS.md only if the pattern recurred or caused real friction
- Work-specific items → AGENTS-work.md, not AGENTS.md
- Single-use fixes → discard (the fix is in the code)
