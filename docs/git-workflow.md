# Git Workflow

Personal git setup — portable baseline in `dotfiles/shell/zshrc`, work overrides in `~/.zshrc.work`.

## Core Aliases (portable)

These work anywhere — pure git, no external dependencies.

### Quick Reference

| Alias | Command | Purpose |
|-------|---------|---------|
| `gs` | `git status` | Working tree status |
| `gd` | `git diff` | Unstaged changes |
| `gds` | `git diff --staged` | Staged changes |
| `ga` | `git add` | Stage files |
| `gc` | `git commit` | Commit |
| `gca` | `git commit --amend --no-edit` | Amend last commit (keep message) |
| `gu` | `git reset --soft HEAD~1` | Undo last commit, keep changes staged |
| `gco` | `git checkout` | Switch branch / restore files |
| `gb` | `git branch` | List/manage branches |
| `gl` | `git log --oneline --graph -20` | Recent history |
| `gpush` | `git push` | Push |
| `gpushup` | `git push --set-upstream origin $(branch)` | Push + set upstream |
| `gpull` | `git pull --rebase --autostash` | Pull with rebase |
| `gf` | `git fetch --prune` | Fetch + prune stale refs |
| `greb` | `git rebase` | Rebase |
| `grebi` | `git rebase -i` | Interactive rebase |
| `grs` | `git restore --staged .` | Unstage everything |
| `gst` | `git stash` | Stash |
| `gstp` | `git stash pop` | Pop stash |
| `greset` | `git reset --hard HEAD` | Discard all uncommitted changes |
| `gprc` | `gh pr checkout` | Checkout a PR locally |
| `gopen` | `gh browse` | Open repo in browser |
| `gpr` | `gh pr view --web` | Open current PR in browser |

### Functions

**`gm`** — Get on fresh main.
```
git fetch origin main && git checkout main && git merge --ff-only origin/main
```
Fast, targeted fetch. No pruning (that's a separate concern). Safe: `--ff-only` fails if local main diverged.

**`gsync`** — Rebase current branch onto latest main.
```
git fetch origin main && git rebase origin/main --autostash
```
Use when your feature branch needs to catch up with main. Autostash handles dirty working tree.

**`gclean`** — Deep cleanup of local branches.
```
git fetch -p
# Delete branches whose remote is gone
git branch -vv | grep 'origin/.*: gone]' | ... | xargs git branch -D
# Delete branches merged into default branch
git branch --merged main | ... | xargs git branch -d
```
Run occasionally when local branches accumulate.

**`gborrow`** — Checkout someone else's remote branch.
```
git fetch origin <branch> && git branch <branch> FETCH_HEAD && git checkout <branch>
```

**`gfresh`** — Hard-reset current branch to its remote.
```
git fetch origin <branch> && git stash && git reset --hard origin/<branch>
```
Nuclear option — stashes local changes, forces branch to match remote exactly.

**`cdg`** — `cd` to repo root.

## git-dd at Work

**git-dd is the gold standard** for git operations in dd-source and other Datadog monorepos. It handles selective branch fetching, which is critical for performance in repos with thousands of remote branches.

### Why git-dd

In dd-source, every developer's branches are on origin. Without filtering, `git fetch` downloads refs for *all* of them — slow and wasteful. git-dd restricts fetches to branches matching your prefix(es), dramatically reducing noise and improving performance.

### Setup

```bash
brew install git-dd
git dd add-branch-prefix $USER          # only track your branches
autoload -Uz _git_dd                    # zsh completions (add to .zshrc)
```

### Commands

| Command | Purpose | Replaces |
|---------|---------|----------|
| `git dd sync` | Pull main + prune + delete merged branches | `gm` + `gclean` |
| `git dd switch <branch>` | Checkout remote branch (prefix-aware) | `gborrow` |
| `git dd prune` | Remove stale tracking branches | `gf` / `gclean` |
| `git dd add-branch-prefix <prefix>` | Track a coworker's branches | — |
| `git dd remove-branch-prefix <prefix>` | Stop tracking a prefix | — |
| `git dd sync-and-rebase` | Sync main + rebase current branch (v1.4+) | `gsync` |
| `git dd new-branch <name>` | Sync + create branch from fresh main (v1.4+) | `gm && gco -b` |
| `git dd doctor` | Diagnose repo issues | — |

### Work Overrides

In `.zshrc.work`, the portable aliases are overridden with git-dd:

```zsh
gm()      { git dd sync; }           # superset: sync + prune + delete merged
gborrow() { git dd switch "$1"; }    # prefix-aware remote checkout
gclean()  { git dd prune; }          # prefix-aware prune
```

Same muscle memory, better implementation at work. On personal machines, the portable versions remain.

### Troubleshooting

- `git fetch` errors → run `git dd prune` to clean stale refspecs
- `fatal: invalid reference: origin/prefix/branch` → use `git dd switch prefix/branch`
- General issues → `git dd doctor`, then #language-tools on Slack
- Never run `git dd restore-defaults` without understanding the consequences

### Reference

- Confluence: https://datadoghq.atlassian.net/wiki/spaces/FF/pages/5695472050/Git+dd
- Claude Code skill: `/git-dd`

## Graphite Workflow

Graphite (`gt`) handles branch stacking and PR management. It coexists with git-dd — different concerns:

- **git-dd** = sync main, manage remote refs, branch prefix filtering
- **Graphite** = stack branches, create/update PRs, manage PR dependencies

### Aliases

| Alias | Command | Purpose |
|-------|---------|---------|
| `gts` | `gt log short --stack` | View current stack |
| `gtsub` | `gt submit` | Create/update PRs for stack |
| `gtr` | `gt restack` | Rebase stack after changes |

### Typical Workflows

**New feature (unrelated to current work):**
```bash
gm                    # get on fresh main (git dd sync at work)
gt create feat/thing  # new branch off main
# ... work ...
gtsub                 # create PR
```

**Extend current work (add to stack):**
```bash
# on current feature branch
gt create feat/next-step   # stack new branch on top
# ... work ...
gtsub                      # create/update PRs for whole stack
```

**Insert a refactor before a feature:**
```bash
# on feature branch that needs a refactor first
gt create refactor/extract-foo   # insert branch in stack
# ... refactor ...
gtr                              # restack: rebase feature on top of refactor
gtsub                            # update all PRs
```

**Sync with latest main:**
```bash
gt sync       # pull latest main into Graphite's tracking
gtr           # rebase stack onto updated main
gtsub         # update PRs
```

**Rebase helper (`.zshrc.work`):**

`reb` is a standalone rebase function for when you're not using Graphite stacks:
- Detects repo (dd-source → main, web-ui → preprod)
- Auto-stashes dirty working tree
- Fetches + rebases onto base branch
- Restores stash after rebase

### How git-dd + Graphite Coexist

1. Use `git dd sync` (via `gm`) to update main — handles prefix filtering
2. Use `gt sync` to tell Graphite about the updated main
3. Use `gtr` to restack your branches
4. Graphite manages the branch DAG; git-dd manages the remote refs

They don't conflict — git-dd operates at the git plumbing level (fetch refspecs, branch cleanup), Graphite operates at the workflow level (stacking, PRs).
