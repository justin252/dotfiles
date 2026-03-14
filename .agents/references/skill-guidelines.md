# Skill Design Guidelines

Auto-consult when building or refining agent skills.

## When to Create a Skill

Skill vs AGENTS.md instruction:
- **Instruction**: single command + context. Fits in one paragraph. e.g., "always use --draft for PRs"
- **Skill**: multi-step workflow, branching logic, cross-repo, or produces artifacts. e.g., /checkpoint, /execute

## Principles

### Blast Radius
Every skill should have a predictable blast radius. Document what it creates, modifies, and never touches.
- Read-only skills (explain, review): no side effects beyond output files
- Write skills (execute, checkpoint): enumerate what gets modified
- Destructive operations: require explicit confirmation, support --dry-run

### Context Budget
Skills run in constrained context windows. Minimize what the agent needs to load.
- Front-load the bootstrap section -- agents read top-down and may stop early
- Reference AGENTS.md for shared conventions instead of duplicating
- Exception: CC subagents are isolated. Duplicate essential conventions inline (commit style, safety rules)

### Composability
Skills should chain naturally without explicit orchestration.
- Output of one skill feeds input of the next (propose -> execute -> checkpoint)
- Use `~/.agents/docs/<topic>/` as the shared state directory
- Standardize artifact names: `problem.md`, `design.md`, `plan.md`, `reference.md`

### Progressive Disclosure
Don't front-load every option. Start simple, reveal complexity on demand.
- Default mode should work with zero configuration
- Advanced modes (autonomous, teach) are opt-in
- Frontmatter `description` field is the first thing users see -- make it actionable

## Structure

```
skills/<name>/SKILL.md
```

Required sections:
1. **Frontmatter**: name, description (one line, starts with verb)
2. **Bootstrap**: how to start (read context, determine arguments, check for existing state)
3. **Workflow**: step-by-step execution
4. **Output**: what artifacts are produced and where

Optional:
- **Modes**: if the skill has execution variants (interactive/autonomous/teach)
- **Conventions**: if running as isolated subagent, duplicate essential rules
- **Principles**: design philosophy specific to this skill

## Naming

- Verb-based: `execute`, `propose`, `explain`, `review`, `checkpoint`
- Match the natural command: what would you type after `/`?
- One skill per verb. Don't create `propose-rfc` and `propose-design` -- one `propose` with variants.

## Testing

A skill is working if:
1. Invoking it with just a topic name produces the expected artifact
2. Re-invoking it with existing state resumes correctly
3. The output is useful without the skill context (standalone doc)
