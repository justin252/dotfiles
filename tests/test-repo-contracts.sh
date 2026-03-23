#!/usr/bin/env bash
# Layer: static / contracts
# What:  validates repo-owned config and doc structure (workflows, JSON, TOML, frontmatter)
# Run:   bash tests/test-repo-contracts.sh
# Add tests here: for new structured config formats or doc contracts that should auto-discover files
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

pass=0 fail=0 skip=0
_pass() { pass=$((pass + 1)); echo "  PASS: $1"; }
_fail() { fail=$((fail + 1)); echo "  FAIL: $1" >&2; }
_skip() { skip=$((skip + 1)); echo "  SKIP: $1"; }

_frontmatter_value() {
  local key="$1" file="$2"
  awk -v key="$key" '
    NR == 1 {
      if ($0 != "---") {
        exit
      }
      in_frontmatter = 1
      next
    }
    in_frontmatter && /^---$/ {
      closed = 1
      in_frontmatter = 0
      exit
    }
    in_frontmatter && $0 ~ ("^" key ":") {
      value = $0
      sub(/^[^:]+:[[:space:]]*/, "", value)
      gsub(/^"/, "", value)
      gsub(/"$/, "", value)
      found = value
    }
    END {
      if (closed && found != "") {
        print found
      }
    }
  ' "$file"
}

_check_json() {
  local file="$1"
  if python3 - "$file" >/dev/null 2>&1 <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as fh:
    json.load(fh)
PY
  then
    _pass "json parses: ${file#$REPO_ROOT/}"
  else
    _fail "json parses: ${file#$REPO_ROOT/}"
  fi
}

_check_toml() {
  local file="$1"
  if python3 - "$file" >/dev/null 2>&1 <<'PY'
import sys
import tomllib

with open(sys.argv[1], "rb") as fh:
    tomllib.load(fh)
PY
  then
    _pass "toml parses: ${file#$REPO_ROOT/}"
  else
    _fail "toml parses: ${file#$REPO_ROOT/}"
  fi
}

echo "=== Workflows ==="

workflow_files=()
while IFS= read -r -d '' file; do
  [[ -f "$REPO_ROOT/$file" ]] || continue
  workflow_files+=("$REPO_ROOT/$file")
done < <(git -C "$REPO_ROOT" ls-files -z -- '.github/workflows/*.yml' '.github/workflows/*.yaml')

if [[ ${#workflow_files[@]} -eq 0 ]]; then
  _skip "no workflow files discovered"
else
  _pass "workflow files discovered: ${#workflow_files[@]}"
  actionlint_bin="${ACTIONLINT:-$(command -v actionlint || true)}"
  if [[ -n "$actionlint_bin" ]]; then
    if "$actionlint_bin" -color "${workflow_files[@]}"; then
      _pass "workflow syntax: actionlint"
    else
      _fail "workflow syntax: actionlint"
    fi
  else
    _skip "workflow syntax: actionlint not installed (brew install actionlint or set ACTIONLINT=/path/to/actionlint)"
  fi
fi

echo ""
echo "=== Structured Config ==="

json_files=()
while IFS= read -r -d '' file; do
  [[ -f "$REPO_ROOT/$file" ]] || continue
  json_files+=("$REPO_ROOT/$file")
done < <(git -C "$REPO_ROOT" ls-files -z -- '*.json')

if [[ ${#json_files[@]} -eq 0 ]]; then
  _skip "no json files discovered"
else
  _pass "json files discovered: ${#json_files[@]}"
  for file in "${json_files[@]}"; do
    _check_json "$file"
  done
fi

toml_files=()
while IFS= read -r -d '' file; do
  [[ -f "$REPO_ROOT/$file" ]] || continue
  toml_files+=("$REPO_ROOT/$file")
done < <(git -C "$REPO_ROOT" ls-files -z -- '*.toml' '*.toml.example')

if [[ ${#toml_files[@]} -eq 0 ]]; then
  _skip "no toml files discovered"
else
  _pass "toml files discovered: ${#toml_files[@]}"
  for file in "${toml_files[@]}"; do
    _check_toml "$file"
  done
fi

git_config_file="$REPO_ROOT/git/config"
if [[ -f "$git_config_file" ]]; then
  if git config -f "$git_config_file" --list >/dev/null 2>&1; then
    _pass "git config parses: git/config"
  else
    _fail "git config parses: git/config"
  fi
else
  _fail "missing git/config"
fi

echo ""
echo "=== Docs ==="

doc_files=()
while IFS= read -r -d '' file; do
  [[ -f "$REPO_ROOT/$file" ]] || continue
  doc_files+=("$REPO_ROOT/$file")
done < <(git -C "$REPO_ROOT" ls-files -z -- '.agents/docs/*.md')

if [[ ${#doc_files[@]} -eq 0 ]]; then
  _skip "no agent docs discovered"
else
  _pass "agent docs discovered: ${#doc_files[@]}"
fi

for file in "${doc_files[@]}"; do
  topic="$(_frontmatter_value topic "$file")"
  status_value="$(_frontmatter_value status "$file")"

  if [[ -n "$topic" ]]; then
    _pass "doc frontmatter topic: ${file#$REPO_ROOT/}"
  else
    _fail "missing doc frontmatter topic: ${file#$REPO_ROOT/}"
  fi

  if [[ -n "$status_value" ]]; then
    _pass "doc frontmatter status: ${file#$REPO_ROOT/}"
  else
    _fail "missing doc frontmatter status: ${file#$REPO_ROOT/}"
  fi
done

echo ""
echo "=== Summary ==="
echo "  pass: $pass  fail: $fail  skip: $skip"
(( fail == 0 )) && echo "  ALL TESTS PASS" || echo "  SOME TESTS FAILED"
exit $fail
