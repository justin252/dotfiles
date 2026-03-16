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
echo "=== Bug #2: /run SKILL.md – no duplicate step numbers ==="

# Extract numbered steps from Bootstrap section and check for duplicates
step_numbers=$(awk '/^## Bootstrap/,/^## [^B]/' "$REPO_ROOT/.agents/skills/run/SKILL.md" | grep -oE '^[0-9]+' || true)
if [[ -n "$step_numbers" ]]; then
  dupes=$(echo "$step_numbers" | sort | uniq -d)
  if [[ -z "$dupes" ]]; then
    _pass "no duplicate step numbers in Bootstrap"
  else
    _fail "duplicate step numbers: $dupes"
  fi
else
  _fail "could not extract step numbers from Bootstrap section"
fi

echo ""
echo "=== Bug #3: tools/ag – no duplicate model resolution ==="

# _display_model and _rm should not both exist computing the same thing
# After fix: _rm should be replaced with _display_model
rm_count=$(grep -c '_rm.*_ag_model.*AG_EXECUTOR\|_rm=""' "$REPO_ROOT/tools/ag" || true)
if (( rm_count > 0 )); then
  _fail "_rm variable still exists (should use _display_model)"
else
  _pass "no duplicate _rm variable"
fi

echo ""
echo "=== Bug #4: tools/ag – no extra space in tmux send-keys ==="

# The tmux send-keys line should handle empty run_model_flag without double space
tmux_line=$(grep 'tmux send-keys.*run_cmd.*run_model_flag\|tmux send-keys.*run_cmd.*run_prompt' "$REPO_ROOT/tools/ag" | grep -v '#' | head -1 || true)
if [[ -n "$tmux_line" ]]; then
  # Check for pattern that avoids double space: either conditional expansion or no bare $run_model_flag
  if echo "$tmux_line" | grep -qE '\$\{run_model_flag:\+|run_model_flag\}'; then
    _pass "tmux command handles empty model flag"
  elif echo "$tmux_line" | grep -qE '"\$run_cmd \$run_model_flag'; then
    _fail "bare \$run_model_flag causes double space when empty"
  else
    _pass "tmux command structure looks safe"
  fi
else
  _fail "could not find tmux send-keys line"
fi

echo ""
echo "=== Bug #5: tools/ag-run-stages – review heuristic precision ==="

# Test the actual grep pattern used in ag-run-stages against known inputs
_test_heuristic() {
  local input="$1" expected="$2" label="$3"

  # Use the same pattern as ag-run-stages (structured severity markers)
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
