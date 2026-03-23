#!/usr/bin/env bash
# Layer: behavioral (integration)
# What:  installs to an isolated HOME and tests real behavior end-to-end
# Run:   bash tests/sandbox.sh
# Add tests here: for tool behavior, CLI error paths, and install/sync contracts
#
# Key techniques:
#   Isolated HOME   – all state goes into a tmpdir; your real machine is untouched
#   Stub PATH       – fake binaries for external deps (fzf, gh, tmux...) so tests
#                     run without those tools installed
#   Function extract – sed extracts pure functions from tools for unit-style testing
#                     without sourcing the whole script (which would run main())
#   _zsh_run        – runs zsh in a subprocess, captures stdout/stderr separately
#                     so we can assert "no stderr" without losing output
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

pass=0 fail=0
_pass() { pass=$((pass + 1)); echo "  PASS: $1"; }
_fail() { fail=$((fail + 1)); echo "  FAIL: $1" >&2; }

SANDBOX=""
ORIG_HOME="$HOME"
ORIG_PATH="$PATH"
ORIG_ZDOTDIR="${ZDOTDIR:-}"
ORIG_WORK_DOTFILES_SET=0
ORIG_WORK_DOTFILES=""
if [[ ${WORK_DOTFILES+set} == set ]]; then
  ORIG_WORK_DOTFILES_SET=1
  ORIG_WORK_DOTFILES="$WORK_DOTFILES"
fi

setup() {
  SANDBOX=$(mktemp -d)
  export HOME="$SANDBOX"
  # ZDOTDIR tells zsh where to find startup files (.zshenv, .zshrc, etc).
  # Without this, zsh uses the passwd-derived home (not $HOME) and reads the
  # real user's .zshenv, which can source files that don't exist in the sandbox.
  export ZDOTDIR="$SANDBOX"
  export WORK_DOTFILES="$SANDBOX/nonexistent-work-dotfiles"

  # Stub external deps: fake binaries that exit 0 so install.sh's `command -v`
  # checks pass without requiring the real tools to be installed.
  # Prepending to PATH means these stubs shadow any real binaries.
  STUB_DIR="$SANDBOX/.stubs"
  mkdir -p "$STUB_DIR"
  for cmd in fzf tmux gh code cursor rtk codex npm brew curl; do
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
  if [[ -n "$ORIG_ZDOTDIR" ]]; then
    export ZDOTDIR="$ORIG_ZDOTDIR"
  else
    unset ZDOTDIR
  fi
  if [[ "$ORIG_WORK_DOTFILES_SET" -eq 0 ]]; then
    unset WORK_DOTFILES
  else
    export WORK_DOTFILES="$ORIG_WORK_DOTFILES"
  fi
  [[ -n "${SANDBOX:-}" ]] && rm -rf "$SANDBOX"
}
trap teardown EXIT

_zsh_run() {
  local label="$1" script="$2"
  local out="$SANDBOX/${label}.out"
  local err="$SANDBOX/${label}.err"
  zsh -c "$script" >"$out" 2>"$err"
  local status=$?
  return "$status"
}

_resolve_dir() {
  local path="$1"
  [[ -d "$path" ]] || return 1
  (
    cd "$path" >/dev/null 2>&1 &&
    pwd -P
  )
}

_json_has_path_entries() {
  local json_input="$1"
  python3 - "$json_input" <<'PY'
import json
import sys

data = json.loads(sys.argv[1])
if not isinstance(data, list):
    raise SystemExit(1)
if not all(isinstance(item, dict) for item in data):
    raise SystemExit(1)
if not any(isinstance(item.get("path"), str) and item["path"] for item in data):
    raise SystemExit(1)
PY
}

# Verifies "flat dir sync" pattern: target is a real directory containing per-file
# symlinks back to source (not a single directory-level symlink). This matters
# because a dir-level symlink would break when work overlays add files.
_assert_flat_dir_sync() {
  local label="$1"
  local source_dir="$REPO_ROOT/.agents/$label"
  local target_dir="$HOME/.agents/$label"
  local source_files=()
  local file fname

  if [[ -d "$target_dir" && ! -L "$target_dir" ]]; then
    _pass "$label: real dir (not symlink)"
  else
    _fail "$label: should be real dir with per-file symlinks, got symlink or missing"
    return
  fi

  while IFS= read -r -d '' file; do
    source_files+=("$file")
  done < <(find "$source_dir" -mindepth 1 -maxdepth 1 -type f -print0)

  if [[ ${#source_files[@]} -gt 0 ]]; then
    _pass "$label source files discovered: ${#source_files[@]}"
  else
    _fail "no $label source files discovered"
    return
  fi

  for file in "${source_files[@]}"; do
    fname="$(basename "$file")"
    if [[ -L "$target_dir/$fname" ]] && [[ "$(readlink "$target_dir/$fname")" == "$file" ]]; then
      _pass "$label symlink: $fname"
    else
      _fail "$label symlink missing/bad: $fname"
    fi
  done

  count=$(find "$target_dir" -mindepth 1 -maxdepth 1 -type l | wc -l | tr -d ' ')
  expected_count="${#source_files[@]}"
  if [[ "$count" == "$expected_count" ]]; then
    _pass "$label count matches source count"
  else
    _fail "$label count mismatch: expected $expected_count, got $count"
  fi
}

_check_flat_dir_doctor_drift() {
  local label="$1"
  local source_dir="$REPO_ROOT/.agents/$label"
  local source_file fname doctor_out

  source_file="$(find "$source_dir" -mindepth 1 -maxdepth 1 -type f | sort | head -n 1)"
  [[ -n "$source_file" ]] || return 0

  fname="$(basename "$source_file")"
  ln -sfn "$REPO_ROOT" "$HOME/.agents/$label/$fname"
  doctor_out=$(DOTFILES="$REPO_ROOT" "$REPO_ROOT/tools/dotfiles" doctor 2>&1 || true)
  if [[ "$doctor_out" == *"$label wrong: $fname"* ]]; then
    _pass "dotfiles doctor: reports wrong $label target"
  else
    _fail "dotfiles doctor should report wrong $label target"
  fi
  DOTFILES="$REPO_ROOT" "$REPO_ROOT/tools/dotfiles" >/dev/null 2>&1 || true
}

_print_summary() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "$pass passed, $fail failed"
  [[ $fail -eq 0 ]] && echo "All tests passed!" || echo "Some tests failed."
  exit "$((fail > 0 ? 1 : 0))"
}

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

# Seeded files
[[ -f "$HOME/.agents/INBOX.md" ]] && _pass "seeded: INBOX.md" || _fail "missing: INBOX.md"

echo ""
echo "=== Shared docs ==="
_assert_flat_dir_sync "conventions"
_assert_flat_dir_sync "docs"

# ━━━ Source ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "=== Source ==="

if zsh -n "$HOME/.zshrc" 2>/dev/null; then
  _pass "zshrc syntax valid"
else
  _fail "zshrc syntax errors"
fi

if _zsh_run "source-once" 'source "$HOME/.zshrc"'; then
  _pass "single source exits clean"
else
  _fail "single source has errors"
fi
if [[ ! -s "$SANDBOX/source-once.err" ]]; then
  _pass "single source emits no stderr"
else
  _fail "single source should not emit stderr: $(tr '\n' '|' < "$SANDBOX/source-once.err")"
fi

if _zsh_run "source-twice" 'source "$HOME/.zshrc"; source "$HOME/.zshrc"'; then
  _pass "double-source clean"
else
  _fail "double-source has errors"
fi
if [[ ! -s "$SANDBOX/source-twice.err" ]]; then
  _pass "double-source emits no stderr"
else
  _fail "double-source should not emit stderr: $(tr '\n' '|' < "$SANDBOX/source-twice.err")"
fi

for fn in gclean gsync gm killport openplan dotfiles; do
  if zsh -c 'source "$HOME/.zshrc"; whence -f '"$fn"' >/dev/null 2>&1' >/dev/null 2>"$SANDBOX/fn-$fn.err"; then
    _pass "function exists: $fn"
  else
    _fail "function missing: $fn"
  fi
done

# ━━━ Shell functions ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "=== Shell functions ==="

# killport: no args should error with usage message
kp_out=$(zsh -c 'source "$HOME/.zshrc"; killport 2>&1; echo "EXIT:$?"' 2>/dev/null)
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

# openplan: with a plan file, should try to open it (stub IDE exits 0)
printf '# Test Plan\nDo stuff\n' > "$HOME/.claude/plans/test-plan.md"
op_out=$(zsh -c 'source "$HOME/.zshrc" 2>/dev/null; openplan 2>&1; echo "EXIT:$?"' 2>/dev/null)
if [[ "$op_out" == *"EXIT:0"* ]]; then
  _pass "openplan: single plan -> opens with IDE (exit 0)"
else
  _fail "openplan: single plan should open with IDE"
fi
rm -f "$HOME/.claude/plans/test-plan.md"

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

# dotfiles: unknown subcommand should fail
if DOTFILES="$REPO_ROOT" "$REPO_ROOT/tools/dotfiles" _refresh-skills >/dev/null 2>&1; then
  _fail "dotfiles: unknown subcommand should error"
else
  _pass "dotfiles: unknown subcommand errors"
fi

# dotfiles: verify symlink repair – break a symlink, run verify, check it's fixed
ln -sfn /nonexistent "$HOME/.agents/AGENTS.md"
DOTFILES="$REPO_ROOT" "$REPO_ROOT/tools/dotfiles" >/dev/null 2>&1 || true
if [[ -L "$HOME/.agents/AGENTS.md" ]] && [[ "$(readlink "$HOME/.agents/AGENTS.md")" == "$REPO_ROOT/.agents/AGENTS.md" ]]; then
  _pass "dotfiles: self-heals broken symlink"
else
  _fail "dotfiles: should repair broken symlink"
fi

# ━━━ wt ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "=== wt ==="

# Extract pure functions from the tool script so we can test them in isolation
# without sourcing the whole file (which would trigger main() and arg parsing).
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

# wt list --json: produces valid JSON array with path entries
json_out=$(cd "$wt_repo" && "$REPO_ROOT/tools/wt" list --json 2>/dev/null)
if _json_has_path_entries "$json_out"; then
  _pass "wt list --json: valid JSON with path field"
else
  _fail "wt list --json: expected valid JSON with path field"
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

# wt clean: removes merged-PR worktrees (mock gh to report branch as merged)
clean_branch="feat/wt-clean-$$"
rmdir "/tmp/wt-$(echo "$clean_branch" | tr '/' '-').lock" 2>/dev/null || true
clean_path=$(cd "$wt_repo" && WT_CREATE_MODE=new "$REPO_ROOT/tools/wt" --quiet new "$clean_branch" 2>/dev/null) || true
cat > "$STUB_DIR/gh" <<'STUBEOF'
#!/bin/bash
# Stub: any pr list call returns a merged PR number
if [[ "$1" == "pr" && "$2" == "list" ]]; then echo "99"; exit 0; fi
exit 0
STUBEOF
chmod +x "$STUB_DIR/gh"
if [[ -n "$clean_path" && -d "$clean_path" ]]; then
  if cd "$wt_repo" && "$REPO_ROOT/tools/wt" --quiet clean --force 2>/dev/null; then
    [[ ! -d "$clean_path" ]] \
      && _pass "wt clean --force: removes merged-PR worktree" \
      || _fail "wt clean: dir still exists after clean"
  else
    _fail "wt clean: command failed"
  fi
else
  _fail "wt clean: setup failed (no worktree created)"
fi
printf '#!/bin/sh\nexit 0\n' > "$STUB_DIR/gh"
chmod +x "$STUB_DIR/gh"

# wt rm: removes worktree (recreate since wt clean above removed it)
rmdir "/tmp/wt-$(echo "$wt_branch" | tr '/' '-').lock" 2>/dev/null || true
result=$(cd "$wt_repo" && WT_CREATE_MODE=new "$REPO_ROOT/tools/wt" --quiet new "$wt_branch" 2>/dev/null) || true
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
# Run under /bin/bash with a stub-only PATH so merged /bin -> /usr/bin setups
# still hide the real tmux/jq binaries.
rm -f "$STUB_DIR/tmux"
ag_out=$(PATH="$STUB_DIR" /bin/bash "$REPO_ROOT/tools/ag" --help 2>&1 || true)
if [[ "$ag_out" == *"missing"* ]]; then
  _pass "ag: missing dep -> clear error"
else
  _fail "ag: missing dep should report error"
fi

# Restore tmux stub
printf '#!/bin/sh\nexit 0\n' > "$STUB_DIR/tmux"
chmod +x "$STUB_DIR/tmux"

# ag open: no worktree -> clear error with suggestion
ag_open_out=$(cd "$wt_repo" && PATH="$STUB_DIR:$ORIG_PATH" /bin/bash "$REPO_ROOT/tools/ag" open nonexistent-topic 2>&1 || true)
if [[ "$ag_open_out" == *"no worktree"* ]]; then
  _pass "ag open: missing worktree -> 'no worktree' error"
else
  _fail "ag open: missing worktree should say 'no worktree', got: $ag_open_out"
fi
if [[ "$ag_open_out" == *"ag new"* ]]; then
  _pass "ag open: missing worktree -> suggests 'ag new'"
else
  _fail "ag open: missing worktree should suggest 'ag new', got: $ag_open_out"
fi

# wt open: missing IDE binary -> non-zero exit + names the command
wt_open_out=$(cd "$wt_repo" && DOTFILES_IDE_CMD=nonexistent-ide-binary WT_CREATE_MODE=new "$REPO_ROOT/tools/wt" open "$wt_branch" 2>&1 || true)
if [[ "$wt_open_out" == *"nonexistent-ide-binary"* ]]; then
  _pass "wt open: missing IDE binary -> names the missing command"
else
  _fail "wt open: missing IDE binary should name the command, got: $wt_open_out"
fi

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

# skills: synced to all runtime destinations
echo ""
echo "=== skills ==="

source_skills=()
for skill_dir in "$REPO_ROOT/.agents/skills"/*; do
  [[ -d "$skill_dir" ]] || continue
  source_skills+=("$(basename "$skill_dir")")
done

if [[ ${#source_skills[@]} -gt 0 ]]; then
  _pass "source skills discovered: ${#source_skills[@]}"
else
  _fail "no source skills discovered"
fi

for skill_name in "${source_skills[@]}"; do
  if [[ -L "$HOME/.agents/skills/$skill_name" ]] && \
     [[ "$(_resolve_dir "$HOME/.agents/skills/$skill_name")" == "$(_resolve_dir "$REPO_ROOT/.agents/skills/$skill_name")" ]]; then
    _pass "agents skill symlink: $skill_name"
  else
    _fail "agents skill symlink missing/bad: $skill_name"
  fi

  if [[ -L "$HOME/.claude/skills/$skill_name" ]] && \
     [[ "$(_resolve_dir "$HOME/.claude/skills/$skill_name")" == "$(_resolve_dir "$REPO_ROOT/.agents/skills/$skill_name")" ]]; then
    _pass "claude skill symlink: $skill_name"
  else
    _fail "claude skill symlink missing/bad: $skill_name"
  fi

  if [[ -d "$HOME/.cursor/skills/$skill_name" && ! -L "$HOME/.cursor/skills/$skill_name" && -f "$HOME/.cursor/skills/$skill_name/SKILL.md" ]]; then
    _pass "cursor skill copy: $skill_name"
  else
    _fail "cursor skill copy missing/bad: $skill_name"
  fi

  if [[ -f "$HOME/.gemini/commands/$skill_name.toml" ]]; then
    _pass "gemini command generated: $skill_name"
  else
    _fail "gemini command missing: $skill_name"
  fi
done

agents_count=$(find "$HOME/.agents/skills" -mindepth 1 -maxdepth 1 -type l | wc -l | tr -d ' ')
claude_count=$(find "$HOME/.claude/skills" -mindepth 1 -maxdepth 1 -type l | wc -l | tr -d ' ')
cursor_count=$(find "$HOME/.cursor/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
gemini_count=$(find "$HOME/.gemini/commands" -mindepth 1 -maxdepth 1 -name '*.toml' | wc -l | tr -d ' ')
expected_count="${#source_skills[@]}"

[[ "$agents_count" == "$expected_count" ]] && _pass "agents skill count matches source count" || _fail "agents skill count mismatch: expected $expected_count, got $agents_count"
[[ "$claude_count" == "$expected_count" ]] && _pass "claude skill count matches source count" || _fail "claude skill count mismatch: expected $expected_count, got $claude_count"
[[ "$cursor_count" == "$expected_count" ]] && _pass "cursor skill count matches source count" || _fail "cursor skill count mismatch: expected $expected_count, got $cursor_count"
[[ "$gemini_count" == "$expected_count" ]] && _pass "gemini command count matches source count" || _fail "gemini command count mismatch: expected $expected_count, got $gemini_count"

# dotfiles doctor should report skill drift, not just missing files
if [[ ${#source_skills[@]} -gt 0 ]]; then
  bad_skill="${source_skills[0]}"
  ln -sfn "$REPO_ROOT" "$HOME/.agents/skills/$bad_skill"
  doctor_out=$(DOTFILES="$REPO_ROOT" "$REPO_ROOT/tools/dotfiles" doctor 2>&1 || true)
  if [[ "$doctor_out" == *"agents wrong: $bad_skill"* ]]; then
    _pass "dotfiles doctor: reports wrong agents skill target"
  else
    _fail "dotfiles doctor should report wrong agents skill target"
  fi
  DOTFILES="$REPO_ROOT" "$REPO_ROOT/tools/dotfiles" >/dev/null 2>&1 || true
fi

_check_flat_dir_doctor_drift "conventions"
_check_flat_dir_doctor_drift "docs"

# ━━━ Stale entry cleanup ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo ""
echo "=== stale cleanup ==="

# Inject a stale skill (symlink to a real dir so it's not "broken", just stale)
ln -sfn "$REPO_ROOT" "$HOME/.agents/skills/fake-stale-skill"
ln -sfn "$REPO_ROOT" "$HOME/.claude/skills/fake-stale-skill"
mkdir -p "$HOME/.cursor/skills/fake-stale-skill"
touch "$HOME/.cursor/skills/fake-stale-skill/SKILL.md"
touch "$HOME/.gemini/commands/fake-stale-skill.toml"

# Doctor should detect it
doctor_out=$(DOTFILES="$REPO_ROOT" "$REPO_ROOT/tools/dotfiles" doctor 2>&1 || true)
if [[ "$doctor_out" == *"agents stale: fake-stale-skill"* ]]; then
  _pass "dotfiles doctor: detects stale skill"
else
  _fail "dotfiles doctor should detect stale skill"
fi

# Sync should remove it
DOTFILES="$REPO_ROOT" "$REPO_ROOT/tools/dotfiles" >/dev/null 2>&1 || true
if [[ ! -e "$HOME/.agents/skills/fake-stale-skill" ]]; then
  _pass "dotfiles sync: removes stale skill from agents"
else
  _fail "dotfiles sync should remove stale skill from agents"
fi
if [[ ! -e "$HOME/.cursor/skills/fake-stale-skill" ]]; then
  _pass "dotfiles sync: removes stale skill from cursor"
else
  _fail "dotfiles sync should remove stale skill from cursor"
fi

# Inject a stale convention symlink
ln -sfn "$REPO_ROOT/README.md" "$HOME/.agents/conventions/fake-stale-conv.md"

# Doctor should detect it
doctor_out=$(DOTFILES="$REPO_ROOT" "$REPO_ROOT/tools/dotfiles" doctor 2>&1 || true)
if [[ "$doctor_out" == *"conventions stale: fake-stale-conv.md"* ]]; then
  _pass "dotfiles doctor: detects stale convention"
else
  _fail "dotfiles doctor should detect stale convention"
fi

# Sync should remove it
DOTFILES="$REPO_ROOT" "$REPO_ROOT/tools/dotfiles" >/dev/null 2>&1 || true
if [[ ! -e "$HOME/.agents/conventions/fake-stale-conv.md" ]]; then
  _pass "dotfiles sync: removes stale convention"
else
  _fail "dotfiles sync should remove stale convention"
fi

# ━━━ Summary ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_print_summary
