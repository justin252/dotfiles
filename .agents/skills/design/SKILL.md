---
name: design
description: Scaffold a design doc from template for a new project or feature.
argument-hint: "[project or feature name]"

---

Scaffold a design doc using the template at `~/dotfiles/templates/DESIGN.md`.

## Flow

1. Ask the user: **new project** or **new feature in an existing repo**?

2. **New project:**
   - Ask for project name (use $ARGUMENTS if provided)
   - Create `~/code/<name>/` (project root)
   - `git init`, create `.gitignore` (include `.DS_Store`)
   - Copy template as `DESIGN.md`, replacing `$PROJECT_NAME` with the project name
   - Walk through each section interactively – ask the user to fill in or skip each one
   - Commit when the user says go

3. **New feature:**
   - Ask for feature name (use $ARGUMENTS if provided)
   - Ask which service/package directory (or use repo root if not a monorepo)
   - Ensure `docs/design/` exists under that directory
   - Create `<dir>/docs/design/<feature>.md` from template
   - Replace `$PROJECT_NAME` with the feature name
   - Skip Architecture section (parent project owns that) – delete it from the copy
   - Walk through remaining sections interactively
   - Commit when the user says go

4. During walkthrough, help the user think through each section. Suggest structure, ask clarifying questions, draft content based on their answers. Iterate until they're happy with each section before moving on.
