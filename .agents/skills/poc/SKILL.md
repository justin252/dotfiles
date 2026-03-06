---
name: poc
description: Prove an idea works – fast, minimal, with gaps documented. Requires `ccy` (dangerously-skip-permissions).

---

Prove an idea works with minimal effort. Research feasibility, build the shortest path, ship a draft PR with documented gaps.

**Requires:** `ccy` (dangerously-skip-permissions). Running from `cc` will hit permission prompts.

## Phase 1: Feasibility

1. Read the idea: $ARGUMENTS (description, issue number, or file path)
2. Explore: existing code, APIs, libraries, constraints
3. Identify the shortest path to "it works"
4. If infeasible, stop early – explain why and suggest alternatives

## Phase 2: Build

1. Create branch: `poc/<slug>` from latest main
2. Implement the shortest path. Explicitly allowed:
   - Hardcoded values, magic strings
   - No tests, no error handling
   - Skipping edge cases
   - Console output instead of proper UI
   - TODO comments for production concerns
3. Get it running / demonstrable

**Scope guard:** if implementation is ballooning past POC, stop and ship what works with a note.

## Phase 3: Ship

1. Commit, push, create draft PR:
   ```
   ## Idea
   <what this proves>

   ## Demo
   <how to run/see it working>

   ## Gaps
   - [ ] <what's hardcoded>
   - [ ] <what's missing for production>
   - [ ] <what needs tests>
   - [ ] <perf concerns>
   - [ ] <security concerns>

   ## Decision log
   - Chose X over Y because <reason>

   ## Next steps
   <what production-izing looks like – estimated scope>
   ```

## Guardrails

- Never merge PRs. Draft only.
- Override behavioral confirmation gates (same as /yolo).
- Hard safety rules still apply (AGENTS.md § Safety).
- Single branch, single PR – no stacking
