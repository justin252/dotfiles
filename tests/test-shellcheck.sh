#!/usr/bin/env bash
# Layer: static analysis
# What:  runs ShellCheck on all tracked bash scripts
# Run:   bash tests/test-shellcheck.sh
# Add tests here: n/a – this auto-discovers bash scripts via shebang
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

pass=0 fail=0 skip=0
_pass() { pass=$((pass + 1)); echo "  PASS: $1"; }
_fail() { fail=$((fail + 1)); echo "  FAIL: $1" >&2; }
_skip() { skip=$((skip + 1)); echo "  SKIP: $1"; }

shellcheck_bin="${SHELLCHECK:-$(command -v shellcheck || true)}"
if [[ -z "$shellcheck_bin" ]]; then
  _skip "shellcheck not installed (brew install shellcheck or set SHELLCHECK=/path/to/shellcheck)"
  echo ""
  echo "=== Summary ==="
  echo "  pass: $pass  fail: $fail  skip: $skip"
  exit 0
fi

echo "=== ShellCheck ==="

# Discover bash scripts by shebang (skip non-script files like .md)
files=()
while IFS= read -r -d '' rel_file; do
  file="$REPO_ROOT/$rel_file"
  [[ -f "$file" ]] || continue
  # Only check actual script files, not docs with embedded shebangs
  case "$rel_file" in *.md) continue ;; esac
  first_line="$(head -n 1 "$file")"
  case "$first_line" in
    '#!/bin/bash'|*'/env bash'*) files+=("$file") ;;
  esac
done < <(git -C "$REPO_ROOT" ls-files -z)

if [[ ${#files[@]} -eq 0 ]]; then
  _skip "no bash scripts discovered"
else
  _pass "bash scripts discovered: ${#files[@]}"
fi

# Run ShellCheck at warning severity (skip info/style)
sc_failed=0
for file in "${files[@]}"; do
  rel="${file#"$REPO_ROOT"/}"
  if "$shellcheck_bin" -S warning "$file" >/dev/null 2>&1; then
    _pass "shellcheck: $rel"
  else
    _fail "shellcheck: $rel"
    # Show the actual warnings for debugging
    "$shellcheck_bin" -S warning "$file" >&2 || true
    sc_failed=1
  fi
done

echo ""
echo "=== Summary ==="
echo "  pass: $pass  fail: $fail  skip: $skip"
(( fail == 0 )) && echo "  ALL TESTS PASS" || echo "  SOME TESTS FAILED"
exit $fail
