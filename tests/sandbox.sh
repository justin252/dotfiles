#!/usr/bin/env bash
# Sandbox test for personal dotfiles – behavior-driven, isolated HOME.
# Run: bash ~/dotfiles/tests/sandbox.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

pass=0 fail=0
_pass() { pass=$((pass + 1)); echo "  PASS: $1"; }
_fail() { fail=$((fail + 1)); echo "  FAIL: $1" >&2; }

SANDBOX=""
ORIG_HOME="$HOME"
ORIG_PATH="$PATH"

setup() {
  SANDBOX=$(mktemp -d)
  export HOME="$SANDBOX"

  # Stub external deps so install.sh skips real installs
  STUB_DIR="$SANDBOX/.stubs"
  mkdir -p "$STUB_DIR"
  for cmd in fzf tmux gh cursor rtk codex npm brew curl; do
    printf '#!/bin/sh\nexit 0\n' > "$STUB_DIR/$cmd"
    chmod +x "$STUB_DIR/$cmd"
  done
  export PATH="$STUB_DIR:$ORIG_PATH"

  # Isolated git config
  git config --global user.email "test@sandbox" 2>/dev/null || true
  git config --global user.name "Sandbox" 2>/dev/null || true
  git config --global init.defaultBranch main 2>/dev/null || true
}

teardown() {
  export HOME="$ORIG_HOME"
  export PATH="$ORIG_PATH"
  [[ -n "${SANDBOX:-}" ]] && rm -rf "$SANDBOX"
}
trap teardown EXIT

# ━━━ Install ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "=== Install ==="

setup

if bash "$REPO_ROOT/install.sh" >/dev/null 2>&1; then
  _pass "install.sh completes"
else
  _fail "install.sh failed"
fi

# Symlinks
for target in .zshrc .tmux.conf; do
  [[ -L "$HOME/$target" ]] && _pass "symlink: ~/$target" || _fail "missing symlink: ~/$target"
done
[[ -L "$HOME/tools" ]] && _pass "symlink: ~/tools" || _fail "missing: ~/tools"
[[ -L "$HOME/.agents/AGENTS.md" ]] && _pass "symlink: ~/.agents/AGENTS.md" || _fail "missing: ~/.agents/AGENTS.md"
[[ -L "$HOME/.claude/CLAUDE.md" ]] && _pass "symlink: ~/.claude/CLAUDE.md" || _fail "missing: ~/.claude/CLAUDE.md"

# zprofile seeded on macOS (homebrew PATH bootstrap for clean machines)
if [[ "$OSTYPE" == darwin* ]]; then
  [[ -f "$HOME/.zprofile" ]] && _pass "seeded: ~/.zprofile" || _fail "missing: ~/.zprofile (clean machine has no homebrew PATH)"
fi

# Dirs
for d in .agents/artifacts .agents/skills .agents/sessions .agents/state .agents/conventions .agents/docs; do
  [[ -d "$HOME/$d" ]] && _pass "dir: ~/$d" || _fail "missing dir: ~/$d"
done

# Conventions + docs: must be real dirs (not symlinks) with per-file symlinks inside
if [[ -d "$HOME/.agents/conventions" && ! -L "$HOME/.agents/conventions" ]]; then
  _pass "conventions: real dir (not symlink)"
else
  _fail "conventions: should be real dir with per-file symlinks, got symlink or missing"
fi
if [[ -L "$HOME/.agents/conventions/shell-scripts.md" ]]; then
  _pass "conventions: per-file symlink (shell-scripts.md)"
else
  _fail "conventions: shell-scripts.md should be a symlink"
fi
if [[ -d "$HOME/.agents/docs" && ! -L "$HOME/.agents/docs" ]]; then
  _pass "docs: real dir (not symlink)"
else
  _fail "docs: should be real dir with per-file symlinks, got symlink or missing"
fi

# Seeded files
[[ -f "$HOME/.agents/INBOX.md" ]] && _pass "seeded: INBOX.md" || _fail "missing: INBOX.md"

# ━━━ Source ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "=== Source ==="

if zsh -n "$HOME/.zshrc" 2>/dev/null; then
  _pass "zshrc syntax valid"
else
  _fail "zshrc syntax errors"
fi

if zsh -c 'source "$HOME/.zshrc" 2>/dev/null; source "$HOME/.zshrc" 2>/dev/null' 2>/dev/null; then
  _pass "double-source clean"
else
  _fail "double-source has errors"
fi

for fn in gclean gsync gm killport openplan dotfiles; do
  if zsh -c 'source "$HOME/.zshrc" 2>/dev/null; whence -f '"$fn"' >/dev/null 2>&1' 2>/dev/null; then
    _pass "function exists: $fn"
  else
    _fail "function missing: $fn"
  fi
done

# ━━━ Shell functions ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "=== Shell functions ==="

# killport: no args should error with usage message
kp_out=$(zsh -c 'source "$HOME/.zshrc" 2>/dev/null; killport 2>&1; echo "EXIT:$?"' 2>/dev/null)
if [[ "$kp_out" == *"EXIT:1"* ]]; then
  _pass "killport: no args -> exit 1"
else
  _fail "killport: no args should exit 1"
fi
if [[ "$kp_out" == *"usage"* ]]; then
  _pass "killport: no args -> usage message"
else
  _fail "killport: no args should print usage"
fi

# openplan: empty plans dir should error
mkdir -p "$HOME/.claude/plans"
op_out=$(zsh -c 'source "$HOME/.zshrc" 2>/dev/null; openplan 2>&1; echo "EXIT:$?"' 2>/dev/null)
if [[ "$op_out" == *"EXIT:1"* ]]; then
  _pass "openplan: empty dir -> exit 1"
else
  _fail "openplan: empty dir should exit 1"
fi
if [[ "$op_out" == *"no plans"* ]]; then
  _pass "openplan: empty dir -> 'no plans' message"
else
  _fail "openplan: empty dir should say 'no plans'"
fi

# ━━━ dotfiles ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "=== dotfiles ==="

# dotfiles --help should show usage
dot_help=$("$REPO_ROOT/tools/dotfiles" --help 2>&1)
if [[ "$dot_help" == *"unified dotfiles sync"* ]]; then
  _pass "dotfiles: --help shows usage"
else
  _fail "dotfiles: --help should show usage"
fi

# dotfiles doctor should run without error in sandbox
if DOTFILES="$REPO_ROOT" "$REPO_ROOT/tools/dotfiles" doctor >/dev/null 2>&1; then
  _pass "dotfiles doctor: completes in sandbox"
else
  _fail "dotfiles doctor: failed in sandbox"
fi

# dotfiles _refresh-skills should work (internal subcommand for install.sh)
if DOTFILES="$REPO_ROOT" "$REPO_ROOT/tools/dotfiles" _refresh-skills >/dev/null 2>&1; then
  _pass "dotfiles _refresh-skills: completes"
else
  _fail "dotfiles _refresh-skills: failed"
fi

# dotfiles: verify symlink repair – break a symlink, run verify, check it's fixed
ln -sfn /nonexistent "$HOME/.agents/AGENTS.md"
dot_out=$(DOTFILES="$REPO_ROOT" "$REPO_ROOT/tools/dotfiles" 2>&1 || true)
if [[ -L "$HOME/.agents/AGENTS.md" ]] && [[ "$(readlink "$HOME/.agents/AGENTS.md")" == "$REPO_ROOT/.agents/AGENTS.md" ]]; then
  _pass "dotfiles: self-heals broken symlink"
else
  _fail "dotfiles: should repair broken symlink"
fi

# ━━━ wt ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "=== wt ==="

# Extract pure functions for unit testing
sed -n '/^slugify()/,/^}/p' "$REPO_ROOT/tools/wt" > "$SANDBOX/.wt-funcs.sh"
sed -n '/^default_branch()/,/^}/p' "$REPO_ROOT/tools/wt" >> "$SANDBOX/.wt-funcs.sh"

# slugify
result=$(bash -c 'source "'"$SANDBOX/.wt-funcs.sh"'" && slugify "feat/my-feature"')
[[ "$result" == "feat-my-feature" ]] \
  && _pass "slugify: feat/my-feature -> feat-my-feature" \
  || _fail "slugify: expected 'feat-my-feature', got '$result'"

result=$(bash -c 'source "'"$SANDBOX/.wt-funcs.sh"'" && slugify "chore/feed-atlas"')
[[ "$result" == "chore-feed-atlas" ]] \
  && _pass "slugify: chore/feed-atlas -> chore-feed-atlas" \
  || _fail "slugify: expected 'chore-feed-atlas', got '$result'"

# default_branch: master-only repo, no origin/HEAD
base="$SANDBOX/repos"
mkdir -p "$base"
git init "$base/master-src" >/dev/null 2>&1
git -C "$base/master-src" checkout -b master >/dev/null 2>&1
git -C "$base/master-src" commit --allow-empty -m "initial" >/dev/null 2>&1
git clone --bare "$base/master-src" "$base/master-repo.git" >/dev/null 2>&1
git clone "$base/master-repo.git" "$base/master-repo" >/dev/null 2>&1
git -C "$base/master-repo" remote set-head origin -d 2>/dev/null || true

result=$(bash -c 'cd "'"$base/master-repo"'" && source "'"$SANDBOX/.wt-funcs.sh"'" && default_branch')
[[ "$result" == "master" ]] \
  && _pass "default_branch: master repo (no origin/HEAD) -> 'master'" \
  || _fail "default_branch: expected 'master', got '$result'"

# default_branch: main-only repo, no origin/HEAD
git init "$base/main-src" >/dev/null 2>&1
git -C "$base/main-src" commit --allow-empty -m "initial" >/dev/null 2>&1
git clone --bare "$base/main-src" "$base/main-repo.git" >/dev/null 2>&1
git clone "$base/main-repo.git" "$base/main-repo" >/dev/null 2>&1
git -C "$base/main-repo" remote set-head origin -d 2>/dev/null || true

result=$(bash -c 'cd "'"$base/main-repo"'" && source "'"$SANDBOX/.wt-funcs.sh"'" && default_branch')
[[ "$result" == "main" ]] \
  && _pass "default_branch: main repo (no origin/HEAD) -> 'main'" \
  || _fail "default_branch: expected 'main', got '$result'"

# wt integration: wt new creates worktree
wt_repo="$base/main-repo"
wt_branch="feat/wt-sandbox-$$"  # unique per PID to avoid lock collisions
rmdir "/tmp/wt-$(echo "$wt_branch" | tr '/' '-').lock" 2>/dev/null || true
result=$(cd "$wt_repo" && WT_CREATE_MODE=new "$REPO_ROOT/tools/wt" --quiet new "$wt_branch" 2>/dev/null) || true
if [[ -n "$result" ]] && [[ -d "$result" ]]; then
  _pass "wt new: creates worktree"
else
  _fail "wt new: failed to create worktree (got '$result')"
fi

# wt new again returns same path (idempotent)
result2=$(cd "$wt_repo" && WT_CREATE_MODE=new "$REPO_ROOT/tools/wt" --quiet new "$wt_branch" 2>/dev/null) || true
# Normalize paths (new may return ../relative, existing returns absolute)
result_norm=$(cd "$result" 2>/dev/null && pwd -P)
result2_norm=$(cd "$result2" 2>/dev/null && pwd -P)
if [[ "$result_norm" == "$result2_norm" ]]; then
  _pass "wt new: idempotent (same path)"
else
  _fail "wt new: expected '$result', got '$result2'"
fi

# wt: unknown subcommand errors (no positional magic)
if cd "$wt_repo" && "$REPO_ROOT/tools/wt" feat/should-error 2>/dev/null; then
  _fail "wt positional: should error on unknown subcommand"
else
  _pass "wt: unknown subcommand errors (no positional magic)"
fi

# wt list --json: produces valid JSON array
json_out=$(cd "$wt_repo" && "$REPO_ROOT/tools/wt" list --json 2>/dev/null)
if echo "$json_out" | grep -q '"path"'; then
  _pass "wt list --json: produces JSON with path field"
else
  _fail "wt list --json: no path field in output"
fi

# wt: PR resolution (mock gh to return branch name)
cat > "$STUB_DIR/gh" <<'STUBEOF'
#!/bin/bash
if [[ "$1" == "pr" && "$2" == "view" ]]; then
  echo "feat/from-pr"
  exit 0
fi
exit 0
STUBEOF
chmod +x "$STUB_DIR/gh"

# Verify resolve_pr_to_branch parses numeric input
sed -n '/^resolve_pr_to_branch()/,/^}/p' "$REPO_ROOT/tools/wt" > "$SANDBOX/.wt-pr.sh"
pr_result=$(bash -c 'export PATH="'"$STUB_DIR"':$PATH"; source "'"$SANDBOX/.wt-pr.sh"'" && resolve_pr_to_branch "42"')
if [[ "$pr_result" == "feat/from-pr" ]]; then
  _pass "wt PR resolve: numeric -> calls gh, gets branch"
else
  _fail "wt PR resolve: expected 'feat/from-pr', got '$pr_result'"
fi

# Restore gh stub
printf '#!/bin/sh\nexit 0\n' > "$STUB_DIR/gh"
chmod +x "$STUB_DIR/gh"

# wt rm: removes worktree
if cd "$wt_repo" && "$REPO_ROOT/tools/wt" --quiet rm "$wt_branch" --force 2>/dev/null; then
  if [[ ! -d "$result" ]]; then
    _pass "wt rm --force: removes worktree"
  else
    _fail "wt rm: dir still exists after rm"
  fi
else
  _fail "wt rm: command failed"
fi

# ━━━ ag ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "=== ag ==="

# _ag_slug: override tmux stub to return AG_SLUG="" and AG_REPO="my-dotfiles"
cat > "$STUB_DIR/tmux" <<'STUBEOF'
#!/bin/bash
if [[ "$1" == "show-environment" ]]; then
  case "$4" in
    AG_SLUG) echo "AG_SLUG="; exit 1 ;;
    AG_REPO) echo "AG_REPO=my-dotfiles" ;;
  esac
  exit 0
fi
exit 0
STUBEOF
chmod +x "$STUB_DIR/tmux"

sed -n '/^_ag_slug()/,/^}/p' "$REPO_ROOT/tools/ag" > "$SANDBOX/.ag-funcs.sh"

# Hyphenated repo name
result=$(bash -c 'export PATH="'"$STUB_DIR"':$PATH"; source "'"$SANDBOX/.ag-funcs.sh"'" && _ag_slug "ag-my-dotfiles-feat"')
[[ "$result" == "feat" ]] \
  && _pass "_ag_slug: ag-my-dotfiles-feat -> feat" \
  || _fail "_ag_slug: expected 'feat', got '$result'"

# Multi-word slug
result=$(bash -c 'export PATH="'"$STUB_DIR"':$PATH"; source "'"$SANDBOX/.ag-funcs.sh"'" && _ag_slug "ag-my-dotfiles-add-feature"')
[[ "$result" == "add-feature" ]] \
  && _pass "_ag_slug: ag-my-dotfiles-add-feature -> add-feature" \
  || _fail "_ag_slug: expected 'add-feature', got '$result'"

# Dep check: ag with missing tmux should exit with clear error.
# Use restricted PATH so the real tmux isn't found either.
rm -f "$STUB_DIR/tmux"
ag_out=$(PATH="$STUB_DIR:/usr/bin:/bin" "$REPO_ROOT/tools/ag" --help 2>&1 || true)
if [[ "$ag_out" == *"missing"* ]]; then
  _pass "ag: missing dep -> clear error"
else
  _fail "ag: missing dep should report error"
fi

# Restore tmux stub
printf '#!/bin/sh\nexit 0\n' > "$STUB_DIR/tmux"
chmod +x "$STUB_DIR/tmux"

# ━━━ artifacts ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "=== artifacts ==="

# Create test artifacts – good frontmatter
mkdir -p "$HOME/.agents/artifacts/test-topic"
cat > "$HOME/.agents/artifacts/test-topic/problem.md" <<'ARTEOF'
---
topic: test-topic
repo: test-repo
status: active
---
# Problem
ARTEOF

# Create artifact with YAML-hostile frontmatter (the exact bug: unquoted *)
cat > "$HOME/.agents/artifacts/test-topic/plan.md" <<'ARTEOF'
---
topic: test-topic
chain: **plan.md**
status: active
---
# Plan
ARTEOF

# Extract batch_frontmatter for direct testing
sed -n '/^batch_frontmatter()/,/^}/p' "$REPO_ROOT/tools/artifacts" > "$SANDBOX/.artifacts-funcs.sh"

# batch_frontmatter should not crash on bad YAML
fm_out=$(bash -c 'source "'"$SANDBOX/.artifacts-funcs.sh"'" && batch_frontmatter "'"$HOME/.agents/artifacts/test-topic/problem.md"'" "'"$HOME/.agents/artifacts/test-topic/plan.md"'"' 2>/dev/null)
if [[ $? -eq 0 ]]; then
  _pass "artifacts: batch_frontmatter survives bad YAML"
else
  _fail "artifacts: batch_frontmatter crashed on bad YAML"
fi

# Good file should still have parsed fields
if echo "$fm_out" | grep -q "test-repo"; then
  _pass "artifacts: good frontmatter parsed correctly"
else
  _fail "artifacts: good frontmatter not parsed"
fi

# Script should reach fzf (stub exits 0 → script exits 0)
if ARTIFACTS_ROOT="$HOME/.agents/artifacts" "$REPO_ROOT/tools/artifacts" >/dev/null 2>&1; then
  _pass "artifacts: runs without crash"
else
  _fail "artifacts: crashed before reaching fzf"
fi

# ━━━ Summary ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]] && echo "All tests passed!" || echo "Some tests failed."
exit "$((fail > 0 ? 1 : 0))"
