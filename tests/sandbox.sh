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
for d in .agents/artifacts .agents/skills .agents/sessions .agents/state; do
  [[ -d "$HOME/$d" ]] && _pass "dir: ~/$d" || _fail "missing dir: ~/$d"
done

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

for fn in gclean gsync gm killport openplan dot; do
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

# ━━━ dot ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "=== dot ==="

# dot --help should show usage
dot_help=$("$REPO_ROOT/tools/dot" --help 2>&1)
if [[ "$dot_help" == *"unified dotfiles sync"* ]]; then
  _pass "dot: --help shows usage"
else
  _fail "dot: --help should show usage"
fi

# dot doctor should run without error in sandbox
if DOTFILES="$REPO_ROOT" "$REPO_ROOT/tools/dot" doctor >/dev/null 2>&1; then
  _pass "dot doctor: completes in sandbox"
else
  _fail "dot doctor: failed in sandbox"
fi

# dot _refresh-skills should work (internal subcommand for install.sh)
if DOTFILES="$REPO_ROOT" "$REPO_ROOT/tools/dot" _refresh-skills >/dev/null 2>&1; then
  _pass "dot _refresh-skills: completes"
else
  _fail "dot _refresh-skills: failed"
fi

# dot: verify symlink repair – break a symlink, run verify, check it's fixed
ln -sfn /nonexistent "$HOME/.agents/AGENTS.md"
dot_out=$(DOTFILES="$REPO_ROOT" "$REPO_ROOT/tools/dot" 2>&1 || true)
if [[ -L "$HOME/.agents/AGENTS.md" ]] && [[ "$(readlink "$HOME/.agents/AGENTS.md")" == "$REPO_ROOT/.agents/AGENTS.md" ]]; then
  _pass "dot: self-heals broken symlink"
else
  _fail "dot: should repair broken symlink"
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

# ━━━ Summary ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]] && echo "All tests passed!" || echo "Some tests failed."
exit "$((fail > 0 ? 1 : 0))"
