#!/usr/bin/env bash
# ag-state.sh - Claude Code hook for agent state persistence
# Fires on Stop (every response) and PreCompact (before context compaction).
# Writes ~/.agents/state/<slug>/context.json so the orchestrator can detect
# context fill and auto-restart agents.
# category: agent
set -euo pipefail

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

state_dir="$HOME/.agents/state/$slug"
mkdir -p "$state_dir"
context_file="$state_dir/context.json"

input=$(cat)
hook_type=$(echo "$input" | jq -r '.hook_type // empty' 2>/dev/null || true)

if [[ "$hook_type" == "Stop" || -z "$hook_type" ]]; then
  summary=$(echo "$input" | jq -r '.last_assistant_message // empty' 2>/dev/null || true)

  relaunch_count=0
  context_filling=false
  if [[ -f "$context_file" ]]; then
    relaunch_count=$(jq -r '.relaunch_count // 0' "$context_file" 2>/dev/null || echo 0)
    context_filling=$(jq -r '.context_filling // false' "$context_file" 2>/dev/null || echo false)
  fi

  sess_name=""
  branch=""
  if [[ -n "${TMUX:-}" ]]; then
    sess_name=$(tmux display-message -p '#{session_name}' 2>/dev/null || true)
    wt_path=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null || true)
    [[ -n "$wt_path" ]] && branch=$(git -C "$wt_path" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  fi

  task=""
  [[ -f "$state_dir/phase" ]] && task=$(cat "$state_dir/phase" 2>/dev/null || true)

  jq -n \
    --arg session "${sess_name:-}" \
    --arg branch "${branch:-}" \
    --arg task "${task:-}" \
    --arg summary "${summary:-}" \
    --argjson context_filling "$context_filling" \
    --argjson relaunch_count "$relaunch_count" \
    --arg updated "$(date -u +%FT%TZ)" \
    '{session:$session,branch:$branch,task:$task,summary:$summary,context_filling:$context_filling,relaunch_count:$relaunch_count,updated:$updated}' \
    > "$context_file.tmp" && mv "$context_file.tmp" "$context_file"
fi

if [[ "$hook_type" == "PreCompact" ]]; then
  trigger=$(echo "$input" | jq -r '.trigger // empty' 2>/dev/null || true)
  if [[ "$trigger" == "auto" ]]; then
    if [[ -f "$context_file" ]]; then
      jq '.context_filling = true | .updated = "'"$(date -u +%FT%TZ)"'"' \
        "$context_file" > "$context_file.tmp" && mv "$context_file.tmp" "$context_file"
    else
      jq -n --arg updated "$(date -u +%FT%TZ)" \
        '{session:"",branch:"",task:"",summary:"",context_filling:true,relaunch_count:0,updated:$updated}' \
        > "$context_file"
    fi
  fi
fi
