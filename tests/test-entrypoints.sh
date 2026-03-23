#!/usr/bin/env bash
# Layer: static
# What:  syntax-checks all tracked scripts by shebang (bash -n, zsh -n, py_compile)
# Run:   bash tests/test-entrypoints.sh
# Add tests here: n/a – auto-discovers scripts by shebang. Just give new scripts a valid shebang.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

pass=0 fail=0 skip=0
_pass() { pass=$((pass + 1)); echo "  PASS: $1"; }
_fail() { fail=$((fail + 1)); echo "  FAIL: $1" >&2; }
_skip() { skip=$((skip + 1)); echo "  SKIP: $1"; }

_check_bash() {
  local file="$1"
  if bash -n "$file"; then
    _pass "bash syntax: ${file#$REPO_ROOT/}"
  else
    _fail "bash syntax: ${file#$REPO_ROOT/}"
  fi
}

_check_zsh() {
  local file="$1"
  if zsh -n "$file"; then
    _pass "zsh syntax: ${file#$REPO_ROOT/}"
  else
    _fail "zsh syntax: ${file#$REPO_ROOT/}"
  fi
}

_check_python() {
  local file="$1"
  if python3 - "$file" >/dev/null 2>&1 <<'PY'
import os
import py_compile
import sys
import tempfile

fd, path = tempfile.mkstemp()
os.close(fd)
try:
    py_compile.compile(sys.argv[1], cfile=path, doraise=True)
finally:
    if os.path.exists(path):
        os.unlink(path)
PY
  then
    _pass "python syntax: ${file#$REPO_ROOT/}"
  else
    _fail "python syntax: ${file#$REPO_ROOT/}"
  fi
}

echo "=== shell/zshrc ==="
_check_zsh "$REPO_ROOT/shell/zshrc"

echo ""
echo "=== Entry points ==="

files=()
while IFS= read -r -d '' rel_file; do
  file="$REPO_ROOT/$rel_file"
  [[ -f "$file" ]] || continue
  first_line="$(sed -n '1p' "$file")"

  case "$first_line" in
    '#!/bin/bash'|*'/env bash'*|*'/env zsh'*|*'/env python3'*|*'uv run --script'*)
      files+=("$file")
      ;;
    '#!'*)
      _fail "unsupported interpreter: $rel_file"
      ;;
  esac
done < <(git -C "$REPO_ROOT" ls-files -z)

if [[ ${#files[@]} -gt 0 ]]; then
  _pass "entry points discovered: ${#files[@]}"
else
  _fail "no entry points discovered"
fi

for file in "${files[@]}"; do
  first_line="$(sed -n '1p' "$file")"
  case "$first_line" in
    '#!/bin/bash'|*'/env bash'*)
      _check_bash "$file"
      ;;
    *'/env zsh'*)
      _check_zsh "$file"
      ;;
    *'/env python3'*|*'uv run --script'*)
      _check_python "$file"
      ;;
    *)
      _skip "unsupported interpreter: ${file#$REPO_ROOT/}"
      ;;
  esac
done

echo ""
echo "=== Summary ==="
echo "  pass: $pass  fail: $fail  skip: $skip"
(( fail == 0 )) && echo "  ALL TESTS PASS" || echo "  SOME TESTS FAILED"
exit $fail
