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

# _has_blockers() detects unchecked P0/P1 action items from review.md.
# Tests verify the production pattern against known inputs.

_test_blocker() {
  local input="$1" expected="$2" label="$3"
  local tmpfile
  tmpfile=$(mktemp)
  echo "$input" > "$tmpfile"
  if grep -qE '^\- \[ \] P[01] ' "$tmpfile" 2>/dev/null; then
    actual="match"
  else
    actual="no-match"
  fi
  rm -f "$tmpfile"
  if [[ "$actual" == "$expected" ]]; then
    _pass "$label"
  else
    _fail "$label (expected=$expected, got=$actual)"
  fi
}

# Unchecked P0/P1 items should trigger fix
_test_blocker "- [ ] P0 Missing null check" "match" "unchecked P0 triggers fix"
_test_blocker "- [ ] P1 Error handling incomplete" "match" "unchecked P1 triggers fix"

# Checked items and P2 should NOT trigger fix
_test_blocker "- [x] P0 Missing null check" "no-match" "checked P0 does not trigger fix"
_test_blocker "- [ ] P2 Consider renaming variable" "no-match" "P2 nit does not trigger fix"
_test_blocker "No issues found. Code looks good." "no-match" "free text does not trigger fix"
_test_blocker "## Blockers" "no-match" "heading alone does not trigger fix"

echo ""
echo "=== Summary ==="
echo "  pass: $pass  fail: $fail"
(( fail == 0 )) && echo "  ALL TESTS PASS" || echo "  SOME TESTS FAILED"
exit $fail
