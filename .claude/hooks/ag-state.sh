#!/usr/bin/env bash
# ag-state.sh - Claude Code hook for agent session state
# Minimal (Phase 5): PreCompact learning flush only
# Phase 1 adds Stop handler and full state management
# category: agent
set -euo pipefail

# Only run inside ag-managed sessions
_get_slug() {
  if [[ -n "${TMUX:-}" ]]; then
    local sess
    sess=$(tmux display-message -p '#{session_name}' 2>/dev/null) || return 1
    local slug
    slug=$(tmux show-environment -t "$sess" AG_SLUG 2>/dev/null | sed 's/^AG_SLUG=//' || true)
    [[ -n "$slug" ]] && echo "$slug" && return 0
  fi
  [[ -n "${AG_SLUG:-}" ]] && echo "$AG_SLUG" && return 0
  return 1
}

slug=$(_get_slug) || exit 0

# Read hook input from stdin
input=$(cat)

# Determine animal from pipeline stage
_current_animal() {
  local state_dir="$HOME/.agents/state/$1"
  if [[ -f "$state_dir/pipeline.json" ]] && command -v jq &>/dev/null; then
    local stage
    stage=$(jq -r '.current_stage // "execute"' "$state_dir/pipeline.json" 2>/dev/null || echo "execute")
    case "$stage" in
      scout|test|execute|verify) echo "dog" ;;
      ship)                      echo "eagle" ;;
      review)                    echo "owl" ;;
      retro)                     echo "elephant" ;;
      *)                         echo "dog" ;;
    esac
  else
    echo "dog"
  fi
}

animal=$(_current_animal "$slug")
learnings_file="$HOME/.agents/learnings/${animal}.md"

# PreCompact: instruct agent to flush learnings before context loss
cat <<EOF
CONTEXT COMPACTION IMMINENT. Before context is lost, flush any accumulated learnings:
- Append observations to $learnings_file (1 line per learning, date-prefixed)
- Only write learnings not already persisted to that file
- Focus on: what patterns worked, what failed, what was surprising
EOF
