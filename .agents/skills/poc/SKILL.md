---
name: poc
description: Prove an idea works – fast, minimal, with gaps documented. Compound skill: /propose (light) -> /execute (phase 1 only) -> /checkpoint. Requires `ccy`.
---

# /poc

Prove an idea works with minimal effort. Compounds three skills into one flow.

**Requires:** `ccy` (dangerously-skip-permissions).

## Flow

1. **Propose (light)**: create `~/.agents/docs/<topic>/problem.md` (lightweight – just Impact + Requirements). Skip design.md – the poc IS the design test. 2-3 minutes max.

2. **Execute (phase 1 only)**: scaffold `plan.md` with a single phase – the shortest path to "it works." Autonomous mode. Explicitly allowed:
   - Hardcoded values, magic strings
   - No tests, no error handling
   - TODO comments for production concerns
   - Console output instead of proper UI

3. **Checkpoint**: commit, push, draft PR:
   ```
   ## Idea
   <what this proves – link to problem.md>

   ## Demo
   <how to run/see it working>

   ## Gaps
   - [ ] <hardcoded values>
   - [ ] <missing for production>
   - [ ] <needs tests>

   ## Next steps
   <what production-izing looks like>
   ```

## Guardrails

- Never merge PRs. Draft only.
- Single branch (`poc/<slug>`), single PR -- no stacking.
- Override confirmation gates. Hard safety rules still apply (AGENTS.md).
- Scope guard: if implementation balloons past poc, stop and ship what works.
- On completion: summarize + terminal notification.
