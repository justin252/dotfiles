# Git Recipes

Advanced git operations. Loaded on demand during complex git work.

## Branch history

- Feature branches: prefer rewriting history (reset + force push) over revert commits. Reverts only on main/shared branches.
- Never `git reset --soft main` -- local main drifts. Use `HEAD~N` (relative) for squashing branch commits.
- Don't auto-squash branch commits at checkpoint -- distinct logical commits (move, fix, feature) tell a story. Ask first.

## Stashing and switching

- Don't stash across branches when files differ. Make changes directly on target branch, or cherry-pick.

## Force push

- `--force-with-lease` stales after rebase; on personal branches use `--force`.

## Tool quirks

- `gh` commands must run from the target repo's cwd. `--repo` flag alone is not enough; `git -C` works for git but not gh.
- After `git mv`, `git add` both old and new paths to ensure rename detection.

## Conflict resolution

- Nested rebase conflicts: `git show <branch>:<file>` to get final intended content from the branch tip. Works when rebasing onto a new base with same content.
