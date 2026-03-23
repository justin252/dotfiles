#!/usr/bin/env bash
# Layer: regression
# What:  targeted checks for past bugs and retired features
# Run:   bash tests/test-regressions.sh
#
# When to add tests here:
#   Permanent regression tests for stable contracts (file existence, behavioral
#   logic). NOT for grep-based source pattern checks – those are TDD scaffolding
#   that should be retired once the guarded refactor lands.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

pass=0 fail=0
_pass() { pass=$((pass + 1)); echo "  PASS: $1"; }
_fail() { fail=$((fail + 1)); echo "  FAIL: $1"; }

echo "=== Retired features ==="

# /run skill was retired (replaced by ag-orchestrate pipeline).
# This is a stable contract: the skill dir must not reappear.
if [[ -f "$REPO_ROOT/.agents/skills/run/SKILL.md" ]]; then
  _fail "/run skill still exists (should be retired)"
else
  _pass "/run skill removed"
fi

echo ""
echo "=== Review heuristic precision ==="

# The ag-orchestrate review stage uses a grep pattern to decide whether a
# review found real issues (blockers/issues) vs just nits. This tests the
# PRODUCTION regex against known inputs to prevent false positives from
# free-text mentions like "no issues found."
#
# Extract the pattern from ag-orchestrate source so the test stays in sync
# with production. If the source pattern changes, this test changes with it.
HEURISTIC_PATTERN=$(grep -oE "'\^\#\{1,3\}[^']+'" "$REPO_ROOT/tools/ag-orchestrate" | tr -d "'" | head -1)
if [[ -z "$HEURISTIC_PATTERN" ]]; then
  _fail "could not extract heuristic pattern from ag-orchestrate"
else
  _pass "extracted heuristic pattern from ag-orchestrate"
fi

_test_heuristic() {
  local input="$1" expected="$2" label="$3"

  # Uses the pattern extracted from the production ag-orchestrate source
  if echo "$input" | grep -qE "$HEURISTIC_PATTERN" 2>/dev/null; then
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

# Structured headers/frontmatter should trigger fixes
_test_heuristic "## Blockers" "match" "## Blockers heading triggers fix"
_test_heuristic "### Issue: missing null check" "match" "### Issue heading triggers fix"
_test_heuristic "severity: blocker" "match" "severity frontmatter triggers fix"

# Free-text mentions should NOT trigger fixes
_test_heuristic "No issues found. Code looks good." "no-match" "free text 'issues' does not trigger fix"
_test_heuristic "All blockers have been resolved." "no-match" "free text 'blockers' does not trigger fix"
_test_heuristic "Only nits and questions." "no-match" "nits-only does not trigger fix"

echo ""
echo "=== Summary ==="
echo "  pass: $pass  fail: $fail"
(( fail == 0 )) && echo "  ALL TESTS PASS" || echo "  SOME TESTS FAILED"
exit $fail
