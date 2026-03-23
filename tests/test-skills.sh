#!/usr/bin/env bash
# Layer: contracts
# What:  validates skill SKILL.md frontmatter (name, description, dir match, uniqueness)
# Run:   bash tests/test-skills.sh
# Add tests here: for new skill source contracts. Auto-discovers skills via git ls-files.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

pass=0 fail=0
_pass() { pass=$((pass + 1)); echo "  PASS: $1"; }
_fail() { fail=$((fail + 1)); echo "  FAIL: $1" >&2; }

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

echo "=== Skills ==="

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

valid_frontmatter="$tmp_dir/valid.md"
prose_before_frontmatter="$tmp_dir/prose-before.md"
missing_closing_frontmatter="$tmp_dir/missing-closing.md"

cat > "$valid_frontmatter" <<'EOF'
---
name: valid
description: "Valid description"
---
body
EOF

cat > "$prose_before_frontmatter" <<'EOF'
intro
---
name: invalid
description: "Should not parse"
---
EOF

cat > "$missing_closing_frontmatter" <<'EOF'
---
name: invalid
description: "Should not parse"
EOF

if [[ "$(_frontmatter_value description "$valid_frontmatter")" == "Valid description" ]]; then
  _pass "strict frontmatter parser accepts valid frontmatter"
else
  _fail "strict frontmatter parser rejected valid frontmatter"
fi

if [[ -z "$(_frontmatter_value description "$prose_before_frontmatter")" ]]; then
  _pass "strict frontmatter parser rejects prose before opening fence"
else
  _fail "strict frontmatter parser accepted prose before opening fence"
fi

if [[ -z "$(_frontmatter_value description "$missing_closing_frontmatter")" ]]; then
  _pass "strict frontmatter parser rejects missing closing fence"
else
  _fail "strict frontmatter parser accepted missing closing fence"
fi

skill_files=()
while IFS= read -r -d '' file; do
  skill_files+=("$REPO_ROOT/$file")
done < <(git -C "$REPO_ROOT" ls-files -z -- '.agents/skills/*/SKILL.md')

if [[ ${#skill_files[@]} -gt 0 ]]; then
  _pass "skill definitions discovered: ${#skill_files[@]}"
else
  _fail "no skill definitions found"
fi

seen_names=$'\n'

for skill_file in "${skill_files[@]}"; do
  skill_dir="$(dirname "$skill_file")"
  skill_dir_name="$(basename "$skill_dir")"
  name="$(_frontmatter_value name "$skill_file")"
  description="$(_frontmatter_value description "$skill_file")"

  if [[ -n "$name" ]]; then
    _pass "frontmatter name: ${skill_file#$REPO_ROOT/}"
  else
    _fail "missing frontmatter name: ${skill_file#$REPO_ROOT/}"
  fi

  if [[ -n "$description" ]]; then
    _pass "frontmatter description: ${skill_file#$REPO_ROOT/}"
  else
    _fail "missing frontmatter description: ${skill_file#$REPO_ROOT/}"
  fi

  if [[ "$name" == "$skill_dir_name" ]]; then
    _pass "skill dir matches name: $skill_dir_name"
  else
    _fail "skill dir/name mismatch: dir=$skill_dir_name name=${name:-<empty>}"
  fi

  if printf '%s' "$seen_names" | grep -qx "$name"; then
    _fail "duplicate skill name: $name"
  else
    seen_names+="$name"$'\n'
    _pass "unique skill name: $name"
  fi
done

echo ""
echo "=== Summary ==="
echo "  pass: $pass  fail: $fail"
(( fail == 0 )) && echo "  ALL TESTS PASS" || echo "  SOME TESTS FAILED"
exit $fail
