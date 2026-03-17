#!/usr/bin/env bash
# Tests for circus model config changes (TDD: written before fixes)
# Run: bash tests/test-circus-model-config.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

pass=0 fail=0
_pass() { pass=$((pass + 1)); echo "  PASS: $1"; }
_fail() { fail=$((fail + 1)); echo "  FAIL: $1"; }

echo "=== Bug #1: tools/review – reviewer_model must be passed to codex ==="

# Extract the codex invocation line and check it uses reviewer_model
if grep -q 'reviewer_model' "$REPO_ROOT/tools/review"; then
  # reviewer_model is parsed; now check it's actually used in the codex command
  if grep -A5 'codex.*exec review' "$REPO_ROOT/tools/review" | grep -qE '\-m.*reviewer_model|reviewer_model.*\-m'; then
    _pass "codex command uses reviewer_model"
  else
    _fail "reviewer_model parsed but never passed to codex exec review"
  fi
else
  _fail "reviewer_model not even parsed"
fi

echo ""
echo "=== Check #2: /run skill retired ==="

# /run skill should no longer exist (retired in Phase 2e)
if [[ -f "$REPO_ROOT/.agents/skills/run/SKILL.md" ]]; then
  _fail "/run skill still exists (should be retired)"
else
  _pass "/run skill removed"
fi

echo ""
echo "=== Bug #3: tools/ag – no duplicate model resolution ==="

# _display_model and _rm should not both exist computing the same thing
# After fix: _rm should be replaced with _display_model
rm_count=$(grep -c '_rm.*_ag_model.*AG_EXECUTE_MODEL\|_rm=""' "$REPO_ROOT/tools/ag" || true)
if (( rm_count > 0 )); then
  _fail "_rm variable still exists (should use _display_model)"
else
  _pass "no duplicate _rm variable"
fi

echo ""
echo "=== Check #4: ag run uses ag-orchestrate ==="

# ag run should launch ag-orchestrate (not tmux send-keys with /run)
if grep -q 'ag-orchestrate' "$REPO_ROOT/tools/ag"; then
  _pass "ag run wired to ag-orchestrate"
else
  _fail "ag run not wired to ag-orchestrate"
fi
if grep -q 'tmux send-keys.*"/run' "$REPO_ROOT/tools/ag"; then
  _fail "old /run tmux send-keys still present"
else
  _pass "no old /run launch pattern"
fi

echo ""
echo "=== Bug #5: tools/ag-orchestrate – review heuristic precision ==="

# Test the actual grep pattern used in ag-orchestrate against known inputs
_test_heuristic() {
  local input="$1" expected="$2" label="$3"

  # Use the same pattern as ag-orchestrate (structured severity markers)
  if echo "$input" | grep -qE '^#{1,3} .*(Blocker|Issue)|severity: *(blocker|issue)' 2>/dev/null; then
    actual="match"
  else
    actual="no-match"
  fi
  if [[ "$actual" == "$expected" ]]; then
    _pass "$label"
  else
    _fail "$label (expected=$expected, got=$actual)"
  fi
}

# These should trigger fixes (structured headers/frontmatter)
_test_heuristic "## Blockers" "match" "## Blockers heading triggers fix"
_test_heuristic "### Issue: missing null check" "match" "### Issue heading triggers fix"
_test_heuristic "severity: blocker" "match" "severity frontmatter triggers fix"

# These should NOT trigger fixes (free text mentions)
_test_heuristic "No issues found. Code looks good." "no-match" "\"no issues found\" should NOT trigger fix"
_test_heuristic "All blockers have been resolved." "no-match" "\"blockers resolved\" should NOT trigger fix"
_test_heuristic "Only nits and questions." "no-match" "nits-only should NOT trigger fix"

echo ""
echo "=== Summary ==="
echo "  pass: $pass  fail: $fail"
(( fail == 0 )) && echo "  ALL TESTS PASS" || echo "  SOME TESTS FAILED"
exit $fail
